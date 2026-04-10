#!/usr/bin/env bash
set -Eeuo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

export SETUP_GITHUB="${SETUP_GITHUB:-1}"
export INSTALL_MCP="${INSTALL_MCP:-0}"
export INSTALL_OPENCODE="${INSTALL_OPENCODE:-1}"

"$ROOT_DIR/setup.sh" "$@"
