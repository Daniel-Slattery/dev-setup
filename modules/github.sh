#!/usr/bin/env bash
set -Eeuo pipefail

SSH_DIR="$HOME/.ssh"
SSH_KEY_PATH="${SSH_KEY_PATH:-$SSH_DIR/id_ed25519}"
SSH_PUB_KEY_PATH="$SSH_KEY_PATH.pub"
SSH_KEY_COMMENT="${SSH_KEY_COMMENT:-${USER}@$(hostname)}"
IS_WSL=0

if [ -r /proc/version ] && grep -qiE '(microsoft|wsl)' /proc/version; then
  IS_WSL=1
fi

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

warn_wsl_oauth_browser_bridge() {
  if [ "$IS_WSL" != "1" ]; then
    return
  fi

  if require_command wslview; then
    return
  fi

  log "WSL detected and wslview is missing"
  log "If browser login does not open automatically, use the shown device URL and code manually"
}

upload_ssh_key_if_possible() {
  if ! gh auth status >/dev/null 2>&1; then
    log "gh is not authenticated yet; skipping automatic SSH key upload"
    return
  fi

  local output
  output="$(gh ssh-key add "$SSH_PUB_KEY_PATH" --title "$(hostname)-$(date +%Y%m%d)" 2>&1 || true)"

  if printf '%s' "$output" | grep -qi 'key is already in use'; then
    log "SSH key already exists on GitHub; continuing"
    return
  fi

  if printf '%s' "$output" | grep -qi 'HTTP 422'; then
    log "GitHub rejected key upload with HTTP 422; likely already registered"
    return
  fi

  if [ -n "$output" ]; then
    log "SSH key upload result: $output"
  else
    log "SSH key uploaded to GitHub"
  fi
}

verify_ssh_auth() {
  local output
  output="$(ssh -T -o BatchMode=yes -o ConnectTimeout=5 git@github.com 2>&1 || true)"

  if printf '%s' "$output" | grep -qi 'successfully authenticated'; then
    log "GitHub SSH auth verified"
    return
  fi

  log "GitHub SSH auth not yet verified. Run: ssh -T git@github.com"
}

print_next_steps() {
  log "GitHub CLI is ready"
  log "Public key path: $SSH_PUB_KEY_PATH"
  printf '\n'
  cat "$SSH_PUB_KEY_PATH"
  printf '\n'
  log "If you are not already authenticated, run: gh auth login"
  log "Recommended options: GitHub.com -> SSH -> Login with a web browser"
  log "Use SSH clone URLs: git@github.com:<owner>/<repo>.git"
  log "Verify SSH auth with: ssh -T git@github.com"
}

main() {
  ensure_gh_available
  warn_wsl_oauth_browser_bridge
  ensure_ssh_dir
  ensure_ssh_key
  gh config set git_protocol ssh >/dev/null
  upload_ssh_key_if_possible
  verify_ssh_auth
  print_next_steps
}

main "$@"
