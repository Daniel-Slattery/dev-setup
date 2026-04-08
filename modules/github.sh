#!/usr/bin/env bash
set -Eeuo pipefail

SSH_DIR="$HOME/.ssh"
SSH_KEY_PATH="${SSH_KEY_PATH:-$SSH_DIR/id_ed25519}"
SSH_PUB_KEY_PATH="$SSH_KEY_PATH.pub"
SSH_KEY_COMMENT="${SSH_KEY_COMMENT:-${USER}@$(hostname)}"

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

ensure_ssh_dir() {
  mkdir -p "$SSH_DIR"
  chmod 700 "$SSH_DIR"
}

ensure_ssh_key() {
  if [ -f "$SSH_KEY_PATH" ] && [ -f "$SSH_PUB_KEY_PATH" ]; then
    log "SSH key already exists: $SSH_KEY_PATH"
    chmod 600 "$SSH_KEY_PATH"
    chmod 644 "$SSH_PUB_KEY_PATH"
    return
  fi

  log "Generating SSH key: $SSH_KEY_PATH"
  ssh-keygen -t ed25519 -C "$SSH_KEY_COMMENT" -f "$SSH_KEY_PATH" -N ""
  chmod 600 "$SSH_KEY_PATH"
  chmod 644 "$SSH_PUB_KEY_PATH"
}

ensure_gh_available() {
  require_command gh || die "gh is required before GitHub setup. Run the main setup first"
}

print_next_steps() {
  log "GitHub CLI is ready"
  log "Public key path: $SSH_PUB_KEY_PATH"
  printf '\n'
  cat "$SSH_PUB_KEY_PATH"
  printf '\n'
  log "If you are not already authenticated, run: gh auth login"
  log "Recommended options: GitHub.com -> SSH -> Login with a web browser"
}

main() {
  ensure_gh_available
  ensure_ssh_dir
  ensure_ssh_key
  gh config set git_protocol ssh >/dev/null
  print_next_steps
}

main "$@"
