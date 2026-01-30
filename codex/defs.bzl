"""Public API for Codex rules."""

load("//codex/private:codex.bzl", _codex = "codex")
load("//codex/private:flags.bzl", _LocalAuthInfo = "LocalAuthInfo", _local_auth_flag = "local_auth_flag")
load("//codex/private:test.bzl", _codex_test = "codex_test")

codex = _codex
codex_test = _codex_test
LocalAuthInfo = _LocalAuthInfo
local_auth_flag = _local_auth_flag
