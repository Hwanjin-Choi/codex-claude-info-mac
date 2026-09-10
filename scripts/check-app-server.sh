#!/bin/zsh
set -euo pipefail
cd "${0:A:h}/.."
CHECK_DIR="$(mktemp -d)"
trap '[[ "$CHECK_DIR" == */tmp.* ]] && rm -rf -- "$CHECK_DIR"' EXIT
cp scripts/fixtures/fake-app-server.py "$CHECK_DIR/fake-server"
chmod +x "$CHECK_DIR/fake-server"
swiftc -parse-as-library Sources/CodexInfo/CodexAppServer.swift \
  scripts/fixtures/check-app-server.swift -o "$CHECK_DIR/check"
"$CHECK_DIR/check" "$CHECK_DIR/fake-server"
