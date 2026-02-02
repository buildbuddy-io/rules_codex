![rules_codex](rules_codex.png)

# rules_codex

Bazel rules for running Codex prompts as build, test, and run actions. Built on top of [tools_codex](https://github.com/buildbuddy-rules/tools_codex), a hermetic, cross-platform Codex toolchain that you can use to write your own ruleset.

## Setup

Add the following to your `MODULE.bazel`:

```python
bazel_dep(name = "rules_codex", version = "0.1.0")
git_override(
    module_name = "rules_codex",
    remote = "https://github.com/buildbuddy-rules/rules_codex.git",
    commit = "d0125df65f10a3c371b9b86563a912ba027b1826",
)

bazel_dep(name = "tools_codex", version = "0.1.0")
git_override(
    module_name = "tools_codex",
    remote = "https://github.com/buildbuddy-rules/tools_codex.git",
    commit = "c795e1880a57cf03d643a91ba59cef05c1717f51",
)
```

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

## Requirements

- Bazel 7.0+ with bzlmod enabled
- Valid `CODEX_API_KEY` environment variable, or local authentication enabled

## Acknowledgements

Codex is a trademark of OpenAI.
