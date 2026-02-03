"""Public API for Codex rules."""

load("//codex/private:codex.bzl", _codex = "codex")
load("//codex/private:flags.bzl", _LocalAuthInfo = "LocalAuthInfo", _local_auth_flag = "local_auth_flag")
load("//codex/private:run.bzl", _codex_run = "codex_run")
load("//codex/private:test.bzl", _codex_test = "codex_test")
load(
    "//codex/private:toolchain.bzl",
    _CODEX_RUNTIME_TOOLCHAIN_TYPE = "CODEX_RUNTIME_TOOLCHAIN_TYPE",
    _CODEX_TOOLCHAIN_TYPE = "CODEX_TOOLCHAIN_TYPE",
    _CodexInfo = "CodexInfo",
    _codex_toolchain = "codex_toolchain",
)

# Rules
codex = _codex
codex_run = _codex_run
codex_test = _codex_test

# Flags
LocalAuthInfo = _LocalAuthInfo
local_auth_flag = _local_auth_flag

# Toolchain
codex_toolchain = _codex_toolchain
CodexInfo = _CodexInfo
CODEX_TOOLCHAIN_TYPE = _CODEX_TOOLCHAIN_TYPE
CODEX_RUNTIME_TOOLCHAIN_TYPE = _CODEX_RUNTIME_TOOLCHAIN_TYPE
