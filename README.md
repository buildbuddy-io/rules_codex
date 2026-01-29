# rules_codex

Bazel rules for running Codex prompts as build actions. Built on top of [tools_codex](https://github.com/buildbuddy-rules/tools_codex).

## Setup

Add the following to your `MODULE.bazel`:

```python
bazel_dep(name = "rules_codex", version = "0.1.0")
git_override(
    module_name = "rules_codex",
    remote = "https://github.com/buildbuddy-rules/rules_codex.git",
    commit = "0e6501faebc7b3430718bdb403a4554c059b32ba",
)
```

Configure your API key in `.bazelrc`:

```
common --action_env=CODEX_API_KEY
```

Then export the key in your environment:

```bash
export CODEX_API_KEY=your-api-key
```

## Usage

```python
load("@rules_codex//codex:defs.bzl", "codex")

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
```

## Rule Reference

### `codex`

Runs Codex with the given prompt and input files to produce an output.

| Attribute | Type | Description |
|-----------|------|-------------|
| `srcs` | `label_list` | Input files to be processed by the prompt. |
| `prompt` | `string` | **Required.** The prompt to send to Codex. |
| `out` | `string` | Output filename. Defaults to `<name>.txt`. |

## Requirements

- Bazel 7.0+ with bzlmod enabled
- Valid `CODEX_API_KEY` environment variable
