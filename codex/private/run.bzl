"""Codex run rule that creates an executable to run prompts via bazel run."""

load(":toolchain.bzl", "CODEX_RUNTIME_TOOLCHAIN_TYPE")

def _shell_quote(s):
    """Quote a string for safe use in shell scripts."""
    return "'" + s.replace("'", "'\"'\"'") + "'"

def _codex_run_impl(ctx):
    """Implementation of the codex_run rule."""
    toolchain = ctx.toolchains[CODEX_RUNTIME_TOOLCHAIN_TYPE]
    codex_binary = toolchain.codex_info.binary

    # Build the prompt
    prompt = ctx.attr.prompt

    # If there are source files, include instructions about them
    src_paths = []
    for src in ctx.files.srcs:
        src_paths.append(src.short_path)

    # Construct the prompt with file references
    full_prompt = prompt
    if src_paths:
        full_prompt = "Input files: " + ", ".join(src_paths) + ". " + full_prompt

    # Add output instruction if out/outs specified
    if ctx.attr.outs:
        full_prompt = full_prompt + " Write the outputs to these files: " + ", ".join(ctx.attr.outs)
    elif ctx.attr.out:
        full_prompt = full_prompt + " Write the output to " + ctx.attr.out

    subcommand = "" if ctx.attr.interactive else "exec --skip-git-repo-check --yolo"
    script = ctx.actions.declare_file(ctx.label.name + ".sh")
    script_content = """#!/bin/bash
set -e
SCRIPT_DIR="$(pwd)"
cd "$BUILD_WORKING_DIRECTORY"
exec "$SCRIPT_DIR/{codex_binary}" {subcommand} {prompt} "$@"
""".format(
        codex_binary = codex_binary.short_path,
        subcommand = subcommand,
        prompt = _shell_quote(full_prompt),
    )
    ctx.actions.write(
        output = script,
        content = script_content,
        is_executable = True,
    )
    runfiles = ctx.runfiles(files = ctx.files.srcs + [codex_binary])
    return [DefaultInfo(
        files = depset([script]),
        executable = script,
        runfiles = runfiles,
    )]

codex_run = rule(
    implementation = _codex_run_impl,
    attrs = {
        "srcs": attr.label_list(
            allow_files = True,
            doc = "Input files to be processed by the prompt.",
        ),
        "prompt": attr.string(
            mandatory = True,
            doc = "The prompt to send to Codex.",
        ),
        "out": attr.string(
            doc = "Output filename.",
        ),
        "outs": attr.string_list(
            doc = "Multiple output filenames.",
        ),
        "interactive": attr.bool(
            default = False,
            doc = "If True, runs in interactive mode.",
        ),
    },
    executable = True,
    toolchains = [CODEX_RUNTIME_TOOLCHAIN_TYPE],
    doc = "Creates an executable that runs Codex with the given prompt. Use with 'bazel run'.",
)
