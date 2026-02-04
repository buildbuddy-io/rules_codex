![rules_codex](rules_codex.png)

# rules_codex

Bazel rules and hermetic toolchain for [Codex](https://github.com/openai/codex) - OpenAI's AI coding CLI. Run Codex prompts as build, test, and run actions, or use the toolchain to write your own rules.

## Setup

Add the following to your `MODULE.bazel`:

```python
bazel_dep(name = "rules_codex", version = "0.1.0")
git_override(
    module_name = "rules_codex",
    remote = "https://github.com/buildbuddy-io/rules_codex.git",
    commit = "053e6d55e8535d21079f611e35fc1620235a3eca",
)
```

The toolchain is automatically registered. By default, it downloads version `rust-v0.92.0` with SHA256 verification for reproducible builds.

### Pinning a Codex version

To pin a specific Codex CLI version:

```starlark
codex = use_extension("@rules_codex//codex:extensions.bzl", "codex")
codex.download(version = "rust-v0.90.0")
```

### Using the latest version

To always fetch the latest version from GitHub releases:

```starlark
codex = use_extension("@rules_codex//codex:extensions.bzl", "codex")
codex.download(use_latest = True)
```

## Running Codex Directly

To launch Codex interactively using the hermetic toolchain:

```bash
bazel run @rules_codex
```

This runs the Codex CLI in interactive mode within your workspace.

## Usage

```python
load("@rules_codex//codex:defs.bzl", "codex", "codex_run", "codex_test")

# Generate documentation from source files
codex(
    name = "generate_docs",
    srcs = ["src/main.py"],
    prompt = "Generate markdown documentation for this Python module.",
    out = "docs.md",
)

# Run a prompt with no input files
codex(
    name = "hello",
    prompt = "Write a haiku about build systems.",
)

# Summarize multiple files
codex(
    name = "summary",
    srcs = [
        "file1.txt",
        "file2.txt",
    ],
    prompt = "Summarize the key points from these files.",
    out = "summary.md",
)

# Generate a complete static marketing website from a README
codex(
    name = "website",
    srcs = ["README.md"],
    prompt = "Generate a complete static marketing website based on this README.",
)

# Interactively refactor code with `bazel run`
codex_run(
    name = "modernize",
    srcs = glob(["src/**/*.py"]),
    prompt = "Refactor this code to use modern Python 3.12 features like pattern matching and type hints.",
)

# Deploy interactively
codex_run(
    name = "deploy",
    srcs = ["main.go"],
    prompt = "Deploy this app to Google Cloud Run. Ask me for any credentials you need and give me links to where I can find them.",
    interactive = True,
)

# Test that documentation is accurate
codex_test(
    name = "validate_readme",
    srcs = ["README.md"],
    prompt = "Walk through this README and verify all the steps work correctly.",
)
```

## Authentication

Codex requires a `CODEX_API_KEY` to function. Since Bazel runs actions in a sandbox, you need to explicitly pass the API key through using `--action_env`.

### Option 1: Pass from environment

To pass the API key from your shell environment, add to your `.bazelrc`:

```
common --action_env=CODEX_API_KEY
```

Then ensure `CODEX_API_KEY` is set in your shell before running Bazel.

### Option 2: Hardcode in user.bazelrc

For convenience, you can hardcode the API key in a `user.bazelrc` file that is gitignored:

1. Add `user.bazelrc` to your `.gitignore`:
   ```
   echo "user.bazelrc" >> .gitignore
   ```

2. Create a `.bazelrc` that imports `user.bazelrc`:
   ```
   echo "try-import %workspace%/user.bazelrc" >> .bazelrc
   ```

3. Create `user.bazelrc` with your API key:
   ```
   common --action_env=CODEX_API_KEY=your-api-key
   ```

### Option 3: Local Authentication

As an alternative to providing an API key, you can use local authentication to run Codex with your existing local credentials. This is useful when you already have Codex configured on your machine.

Enable local auth mode with the `--@rules_codex//:local_auth` flag:

```bash
bazel build //my:target --@rules_codex//:local_auth
```

When local auth is enabled:
- The action runs locally (not sandboxed)
- Your real `HOME` directory is used, allowing Codex to access your local configuration and credentials

### Setting up a flag alias

To use a shorter flag name, add a flag alias to your `.bazelrc`:

```
common --flag_alias=codex_local_auth=@rules_codex//:local_auth
```

Then you can use:

```bash
bazel build //my:target --codex_local_auth
```

## Rule Reference

### `codex`

Runs Codex with the given prompt and input files to produce an output.

| Attribute | Type | Description |
|-----------|------|-------------|
| `srcs` | `label_list` | Input files to be processed by the prompt. |
| `prompt` | `string` | **Required.** The prompt to send to Codex. |
| `out` | `string` | Output filename. If not specified, outputs to a directory. |
| `outs` | `string_list` | Multiple output filenames. Takes precedence over `out`. |
| `local_auth` | `label` | Flag to enable local auth mode. Defaults to `@rules_codex//:local_auth`. |

### `codex_run`

Creates an executable that runs Codex with the given prompt. Use with `bazel run`.

| Attribute | Type | Description |
|-----------|------|-------------|
| `srcs` | `label_list` | Input files to be processed by the prompt. |
| `prompt` | `string` | **Required.** The prompt to send to Codex. |
| `out` | `string` | Output filename to include in the prompt. |
| `outs` | `string_list` | Multiple output filenames to include in the prompt. |

### `codex_test`

Runs Codex with the given prompt as a Bazel test. The agent evaluates the prompt and writes a result file with `PASS` or `FAIL` on the first line, followed by an explanation.

| Attribute | Type | Description |
|-----------|------|-------------|
| `srcs` | `label_list` | Input files to be processed by the prompt. |
| `prompt` | `string` | **Required.** The prompt describing what to test and the pass/fail criteria. |
| `local_auth` | `label` | Flag to enable local auth mode. Defaults to `@rules_codex//:local_auth`. |

## Toolchain API

The rules above are built on a hermetic, cross-platform toolchain that you can use directly to write your own rules.

### In genrule

Use the toolchain in a genrule via `toolchains` and make variable expansion:

```starlark
load("@rules_codex//codex:defs.bzl", "CODEX_TOOLCHAIN_TYPE")

genrule(
    name = "my_genrule",
    srcs = ["input.py"],
    outs = ["output.md"],
    cmd = """
        export HOME=.home
        $(CODEX_BINARY) exec --skip-git-repo-check --yolo \
            'Read $(location input.py) and write API documentation to $@'
    """,
    toolchains = [CODEX_TOOLCHAIN_TYPE],
)
```

The `$(CODEX_BINARY)` make variable expands to the path of the Codex binary.

**Note:** The `export HOME=.home` line is required because Bazel runs genrules in a sandbox where the real home directory is not writable. Codex writes session files to `$HOME`, so redirecting it to a writable location within the sandbox prevents permission errors. The `--skip-git-repo-check` flag is needed since the sandbox is not a git repository, and `--yolo` allows Codex to read and write files without restrictions.

### In custom rules

Use the toolchain in your rule implementation:

```starlark
load("@rules_codex//codex:defs.bzl", "CODEX_TOOLCHAIN_TYPE")

def _my_rule_impl(ctx):
    toolchain = ctx.toolchains[CODEX_TOOLCHAIN_TYPE]
    codex_binary = toolchain.codex_info.binary

    out = ctx.actions.declare_file(ctx.label.name + ".md")
    ctx.actions.run(
        executable = codex_binary,
        arguments = [
            "exec",
            "--skip-git-repo-check",
            "--yolo",
            "Read {} and write API documentation to {}".format(ctx.file.src.path, out.path),
        ],
        inputs = [ctx.file.src],
        outputs = [out],
        env = {"HOME": ".home"},
        use_default_shell_env = True,
    )
    return [DefaultInfo(files = depset([out]))]

my_rule = rule(
    implementation = _my_rule_impl,
    attrs = {
        "src": attr.label(allow_single_file = True, mandatory = True),
    },
    toolchains = [CODEX_TOOLCHAIN_TYPE],
)
```

### In tests

For tests that need to run the Codex binary at runtime, use the runtime toolchain type. This ensures the binary matches the target platform where the test executes:

```starlark
load("@rules_codex//codex:defs.bzl", "CODEX_RUNTIME_TOOLCHAIN_TYPE")

def _codex_test_impl(ctx):
    toolchain = ctx.toolchains[CODEX_RUNTIME_TOOLCHAIN_TYPE]
    codex_binary = toolchain.codex_info.binary

    test_script = ctx.actions.declare_file(ctx.label.name + ".sh")
    ctx.actions.write(
        output = test_script,
        content = """#!/bin/bash
export HOME="$TEST_TMPDIR"
{codex} --version
""".format(codex = codex_binary.short_path),
        is_executable = True,
    )
    return [DefaultInfo(
        executable = test_script,
        runfiles = ctx.runfiles(files = [codex_binary]),
    )]

codex_test = rule(
    implementation = _codex_test_impl,
    test = True,
    toolchains = [CODEX_RUNTIME_TOOLCHAIN_TYPE],
)
```

### Toolchain types

There are two toolchain types depending on your use case:

- **`CODEX_TOOLCHAIN_TYPE`** - Use for build-time actions (genrules, custom rules). Selected based on the execution platform. Use this when Codex's output isn't platform-specific.

- **`CODEX_RUNTIME_TOOLCHAIN_TYPE`** - Use for tests or run targets where the Codex binary executes on the target platform.

### Public API

From `@rules_codex//codex:defs.bzl`:

| Symbol | Description |
|--------|-------------|
| `codex` | Rule for running Codex prompts as build actions |
| `codex_run` | Rule for running Codex prompts with `bazel run` |
| `codex_test` | Rule for running Codex prompts as tests |
| `CODEX_TOOLCHAIN_TYPE` | Toolchain type for build actions (exec platform) |
| `CODEX_RUNTIME_TOOLCHAIN_TYPE` | Toolchain type for test/run (target platform) |
| `CodexInfo` | Provider with `binary` field containing the Codex executable |
| `codex_toolchain` | Rule for defining custom toolchain implementations |
| `LocalAuthInfo` | Provider for local auth flag |
| `local_auth_flag` | Rule for defining local auth build settings |

## Supported platforms

- `darwin_arm64` (macOS Apple Silicon)
- `darwin_amd64` (macOS Intel)
- `linux_arm64`
- `linux_amd64`
- `windows_arm64`
- `windows_amd64`

## Requirements

- Bazel 7.0+ with bzlmod enabled
- Valid `CODEX_API_KEY` environment variable, or local authentication enabled

## Acknowledgements

Codex is a trademark of OpenAI.
