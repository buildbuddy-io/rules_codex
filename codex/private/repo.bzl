"""Repository rule for downloading the Codex CLI binary."""

_CODEX_VERSION = "rust-v0.92.0"
_CODEX_BASE_URL = "https://github.com/openai/codex/releases/download/{version}"
_CODEX_RELEASES_API = "https://api.github.com/repos/openai/codex/releases/latest"

# SHA256 hashes for the default version (rust-v0.92.0)
# To find hashes for other versions, run:
#   curl -s "https://api.github.com/repos/openai/codex/releases/tags/VERSION" | \
#     jq '.assets[] | {name: .name, digest: .digest}'
_DEFAULT_HASHES = {
    "darwin_arm64": "1a063ed387bb05ef0b2875a96417697308975ed657e019578bc478d74c1e2889",
    "darwin_amd64": "7abefc8e36df743c7acfe5246293e3fd2e2958b137c9776f976aed8e3a91c9e9",
    "linux_arm64": "b742a6c534ac92ba9ca84dc15e0ea3ebbc0bdced0591e3b56b5a77cb31d61675",
    "linux_amd64": "757c00c23c69d61a8e372d9a05266bba0d6107058ad8902dd818b787f4825b31",
    "windows_arm64": "c161f340680601cf8021e187aaf5d5628848c6cbf4fd91a7ed2f76d4aa422fa5",
    "windows_amd64": "5d0029f49e1756cd127d3f2d57baae11b1768d676c2e939e5fc546639f923903",
}

_PLATFORMS = {
    "darwin_arm64": {
        "filename": "codex-aarch64-apple-darwin.tar.gz",
        "extracted": "codex-aarch64-apple-darwin",
        "binary": "codex",
    },
    "darwin_amd64": {
        "filename": "codex-x86_64-apple-darwin.tar.gz",
        "extracted": "codex-x86_64-apple-darwin",
        "binary": "codex",
    },
    "linux_arm64": {
        "filename": "codex-aarch64-unknown-linux-musl.tar.gz",
        "extracted": "codex-aarch64-unknown-linux-musl",
        "binary": "codex",
    },
    "linux_amd64": {
        "filename": "codex-x86_64-unknown-linux-musl.tar.gz",
        "extracted": "codex-x86_64-unknown-linux-musl",
        "binary": "codex",
    },
    "windows_arm64": {
        "filename": "codex-aarch64-pc-windows-msvc.tar.gz",
        "extracted": "codex-aarch64-pc-windows-msvc.exe",
        "binary": "codex.exe",
    },
    "windows_amd64": {
        "filename": "codex-x86_64-pc-windows-msvc.tar.gz",
        "extracted": "codex-x86_64-pc-windows-msvc.exe",
        "binary": "codex.exe",
    },
}

def _get_platform(repository_ctx):
    """Determine the current platform."""
    os_name = repository_ctx.os.name.lower()
    arch = repository_ctx.os.arch

    if "mac" in os_name or "darwin" in os_name:
        os_key = "darwin"
    elif "linux" in os_name:
        os_key = "linux"
    elif "win" in os_name:
        os_key = "windows"
    else:
        fail("Unsupported operating system: {}".format(os_name))

    if arch == "aarch64" or arch == "arm64":
        arch_key = "arm64"
    elif arch == "x86_64" or arch == "amd64":
        arch_key = "amd64"
    else:
        fail("Unsupported architecture: {}".format(arch))

    return "{}_{}".format(os_key, arch_key)

def _get_digest_from_assets(assets, filename):
    """Extract SHA256 hash from release assets for the given filename."""
    for asset in assets:
        if asset.get("name") == filename:
            digest = asset.get("digest", "")
            # digest format is "sha256:hash", extract just the hash
            if digest.startswith("sha256:"):
                return digest[7:]
            return digest
    return ""

def _codex_toolchains_impl(repository_ctx):
    """Download and extract the Codex binary for the specified or current platform."""
    # Use specified platform or detect current
    platform = repository_ctx.attr.platform
    if not platform:
        platform = _get_platform(repository_ctx)

    if platform not in _PLATFORMS:
        fail("Unsupported platform: {}".format(platform))

    platform_info = _PLATFORMS[platform]
    filename = platform_info["filename"]
    extracted = platform_info["extracted"]
    binary = platform_info["binary"]

    # Determine version and hash
    use_latest = repository_ctx.attr.use_latest
    version = repository_ctx.attr.version
    sha256 = repository_ctx.attr.sha256

    if use_latest:
        # Fetch latest version from GitHub API
        repository_ctx.report_progress("Fetching latest Codex version...")
        repository_ctx.download(
            url = _CODEX_RELEASES_API,
            output = "release.json",
        )
        release_json = json.decode(repository_ctx.read("release.json"))
        version = release_json["tag_name"]
        # Extract hash from release assets
        sha256 = _get_digest_from_assets(release_json.get("assets", []), filename)
        repository_ctx.delete("release.json")
    elif not version:
        # Use default version with default hash
        version = _CODEX_VERSION
        if not sha256:
            sha256 = _DEFAULT_HASHES.get(platform, "")

    url = "{}/{}".format(
        _CODEX_BASE_URL.format(version = version),
        filename,
    )

    repository_ctx.report_progress("Downloading Codex {} for {}".format(version, platform))

    # Download and extract the .tar.gz file
    download_kwargs = {"url": url}
    if sha256:
        download_kwargs["sha256"] = sha256
    repository_ctx.download_and_extract(**download_kwargs)

    # Rename extracted binary to expected name
    repository_ctx.execute(["mv", extracted, binary])

    # Make executable on Unix
    if "windows" not in platform:
        repository_ctx.execute(["chmod", "+x", binary])

    # Write version file for reference
    repository_ctx.file("VERSION", version)

    # Create BUILD file - always export as "codex" for consistent referencing
    if "windows" in platform:
        build_content = '''
package(default_visibility = ["//visibility:public"])

exports_files(["codex.exe"])

# Alias for consistent cross-platform referencing
alias(
    name = "codex",
    actual = "codex.exe",
)
'''
    else:
        build_content = '''
package(default_visibility = ["//visibility:public"])

exports_files(["codex"])
'''

    repository_ctx.file("BUILD.bazel", content = build_content)

codex_toolchains = repository_rule(
    implementation = _codex_toolchains_impl,
    attrs = {
        "version": attr.string(
            doc = "Version to download. If empty, uses default version.",
        ),
        "platform": attr.string(
            doc = "Platform to download for (e.g., 'darwin_arm64'). If empty, detects current platform.",
        ),
        "sha256": attr.string(
            doc = "SHA256 hash of the archive for this platform.",
        ),
        "use_latest": attr.bool(
            default = False,
            doc = "If true, fetches the latest version from GitHub releases instead of the default.",
        ),
    },
    doc = "Downloads the Codex CLI binary for the specified platform.",
)

CODEX_DEFAULT_VERSION = _CODEX_VERSION
CODEX_DEFAULT_HASHES = _DEFAULT_HASHES
