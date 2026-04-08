#!/usr/bin/env bash
set -Eeuo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
CONFIG_DIR="$ROOT_DIR/config"
MCP_ENV_TEMPLATE="$CONFIG_DIR/mcp.env.example"
MCP_ENV_FILE="$CONFIG_DIR/mcp.env"
MCP_MANIFEST="$CONFIG_DIR/mcp-servers.txt"

log() {
  printf '\n[%s] %s\n' "$(date '+%H:%M:%S')" "$1"
}

die() {
  printf '\n[ERROR] %s\n' "$1" >&2
  exit 1
}

require_command() {
  command -v "$1" >/dev/null 2>&1
}

ensure_mcp_env_file() {
  [ -f "$MCP_ENV_TEMPLATE" ] || die "Missing MCP env template at $MCP_ENV_TEMPLATE"

  if [ -f "$MCP_ENV_FILE" ]; then
    log "MCP env file already exists: $MCP_ENV_FILE"
    return
  fi

  log "Creating MCP env file from template: $MCP_ENV_FILE"
  cp "$MCP_ENV_TEMPLATE" "$MCP_ENV_FILE"
  log "Fill in required secrets in $MCP_ENV_FILE before enabling secret-backed servers"
}

load_mcp_env() {
  ensure_mcp_env_file

  set -a
  # shellcheck disable=SC1090
  . "$MCP_ENV_FILE"
  set +a
}

ensure_codex_available() {
  if require_command codex; then
    log "Codex CLI already available"
    return
  fi

  die "Codex CLI is required before MCP setup. Run the main setup first"
}

ensure_manifest_exists() {
  [ -f "$MCP_MANIFEST" ] || die "Missing MCP manifest at $MCP_MANIFEST"
}

process_manifest() {
  local line
  local name
  local runtime
  local install_mode
  local package
  local env_vars
  local install_cmd

  ensure_manifest_exists

  while IFS='|' read -r name runtime install_mode package env_vars install_cmd; do
    [ -n "$name" ] || continue
    [[ "$name" = \#* ]] && continue

    case "$install_mode" in
      npm-global)
        if npm list -g --depth=0 "$package" >/dev/null 2>&1; then
          log "MCP package already installed for $name: $package"
        else
          log "Installing MCP package for $name: $package"
          npm install -g "$package"
        fi
        ;;
      manual)
        log "Skipping auto-install for $name"
        log "Manual step: $install_cmd"
        ;;
      *)
        log "Skipping $name because install mode is unsupported: $install_mode"
        ;;
    esac

    if [ -n "$env_vars" ] && [ "$env_vars" != "-" ]; then
      log "Required env vars for $name: $env_vars"
    fi
  done < "$MCP_MANIFEST"
}

main() {
  log "Starting optional MCP setup"
  ensure_codex_available
  load_mcp_env
  process_manifest
  log "MCP setup complete"
}

main "$@"
