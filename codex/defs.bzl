"""Codex rule that takes prompt inputs and produces outputs."""

load("@tools_codex//codex:defs.bzl", "CODEX_TOOLCHAIN_TYPE")

def _codex_impl(ctx):
    """Implementation of the codex rule."""
    toolchain = ctx.toolchains[CODEX_TOOLCHAIN_TYPE]
    codex_binary = toolchain.codex_info.binary

    # Determine output file
    if ctx.attr.out:
        out = ctx.actions.declare_file(ctx.attr.out)
    else:
        out = ctx.actions.declare_file(ctx.label.name + ".txt")

    # Build the prompt
    prompt = ctx.attr.prompt

    # If there are source files, include instructions about them
    src_paths = []
    for src in ctx.files.srcs:
        src_paths.append(src.path)

    # Build arguments for codex exec
    args = ctx.actions.args()
    args.add("exec")
    args.add("--skip-git-repo-check")
    args.add("--yolo")

    # Construct the full prompt with file references and output path
    full_prompt = prompt
    if src_paths:
        full_prompt = "Input files: " + ", ".join(src_paths) + ". " + full_prompt
    full_prompt = full_prompt + " Write the output to " + out.path

    args.add(full_prompt)

    ctx.actions.run(
        executable = codex_binary,
        arguments = [args],
        inputs = ctx.files.srcs,
        outputs = [out],
        env = {"HOME": ".home"},
        use_default_shell_env = True,
        mnemonic = "Codex",
        progress_message = "Running Codex: %s" % ctx.label,
    )

    return [DefaultInfo(files = depset([out]))]

codex = rule(
    implementation = _codex_impl,
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
            doc = "Output filename. Defaults to <name>.txt if not specified.",
        ),
    },
    toolchains = [CODEX_TOOLCHAIN_TYPE],
    doc = "Runs Codex with the given prompt and input files to produce an output.",
)
