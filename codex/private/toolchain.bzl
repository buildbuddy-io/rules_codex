"""Codex toolchain definitions."""

CodexInfo = provider(
    doc = "Information about the Codex CLI.",
    fields = {
        "binary": "The Codex executable file.",
    },
)

def _codex_toolchain_impl(ctx):
    """Implementation of the Codex toolchain."""
    default_info = DefaultInfo(files = depset([ctx.file.codex]))
    toolchain_info = platform_common.ToolchainInfo(
        codex_info = CodexInfo(
            binary = ctx.file.codex,
        ),
    )
    template_variable_info = platform_common.TemplateVariableInfo({
        "CODEX_BINARY": ctx.file.codex.path,
    })
    return [default_info, toolchain_info, template_variable_info]

codex_toolchain = rule(
    implementation = _codex_toolchain_impl,
    attrs = {
        "codex": attr.label(
            doc = "The Codex CLI binary.",
            allow_single_file = True,
            mandatory = True,
        ),
    },
    doc = "Defines a Codex toolchain.",
)

CODEX_TOOLCHAIN_TYPE = "@rules_codex//codex:toolchain_type"
CODEX_RUNTIME_TOOLCHAIN_TYPE = "@rules_codex//codex:runtime_toolchain_type"
