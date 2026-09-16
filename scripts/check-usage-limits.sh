#!/bin/zsh
set -euo pipefail
cd "${0:A:h}/.."
CHECK_DIR="$(mktemp -d)"
trap '[[ "$CHECK_DIR" == */tmp.* ]] && rm -rf -- "$CHECK_DIR"' EXIT
swiftc -parse-as-library Sources/CodexInfo/Models.swift Sources/CodexInfo/CodexRateLimits.swift \
  scripts/fixtures/check-usage-limits.swift -o "$CHECK_DIR/check"
"$CHECK_DIR/check" scripts/fixtures/rate-limits.json
