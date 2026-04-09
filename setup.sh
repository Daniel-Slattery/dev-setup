#!/usr/bin/env bash
set -Eeuo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ZSHRC_SOURCE="$SCRIPT_DIR/zshrc"
ZSHRC_APPEND_SOURCE="$SCRIPT_DIR/zshrc.append"
ZSHRC_TARGET="$HOME/.zshrc"
BASHRC_TARGET="$HOME/.bashrc"
MCP_SETUP_SCRIPT="$SCRIPT_DIR/modules/mcp.sh"
GITHUB_SETUP_SCRIPT="$SCRIPT_DIR/modules/github.sh"
NVM_DIR="${NVM_DIR:-$HOME/.nvm}"
OH_MY_ZSH_DIR="${ZSH:-$HOME/.oh-my-zsh}"
P10K_DIR="${ZSH_CUSTOM:-$OH_MY_ZSH_DIR/custom}/themes/powerlevel10k"
DEV_SETUP_CONFIG_DIR="$HOME/.config/dev-setup"
SHARED_PATH_FILE="$DEV_SETUP_CONFIG_DIR/path.sh"
OS_TYPE="$(uname -s)"
INSTALL_MCP="${INSTALL_MCP:-0}"
SETUP_GITHUB="${SETUP_GITHUB:-0}"
SET_DEFAULT_SHELL="${SET_DEFAULT_SHELL:-0}"
CONFIGURE_WT_SHIFT_ENTER="${CONFIGURE_WT_SHIFT_ENTER:-1}"
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

on_error() {
  local exit_code=$?
  printf '\n[ERROR] setup failed at line %s with exit code %s\n' "${BASH_LINENO[0]}" "$exit_code" >&2
  exit "$exit_code"
}

trap on_error ERR

require_sudo() {
  if ! command -v sudo >/dev/null 2>&1; then
    die "sudo is required but not installed"
  fi
}

require_command() {
  command -v "$1" >/dev/null 2>&1
}

ensure_file_exists() {
  local file="$1"

  if [ -f "$file" ]; then
    return
  fi

  touch "$file"
}

ensure_line_in_file() {
  local file="$1"
  local line="$2"

  ensure_file_exists "$file"

  if grep -Fqx "$line" "$file"; then
    return
  fi

  printf '\n%s\n' "$line" >>"$file"
}

backup_file_once() {
  local file="$1"
  local backup="$2"

  if [ -f "$file" ] && [ ! -f "$backup" ]; then
    cp "$file" "$backup"
  fi
}

remove_pattern_from_file() {
  local file="$1"
  local regex="$2"
  local backup_suffix="$3"

  if [ ! -f "$file" ]; then
    return
  fi

  if ! grep -Eq "$regex" "$file"; then
    return
  fi

  local tmp_file
  tmp_file="$(mktemp)"
  grep -Ev "$regex" "$file" >"$tmp_file" || true
  backup_file_once "$file" "$file.$backup_suffix"
  mv "$tmp_file" "$file"
}

apt_pkg_installed() {
  dpkg -s "$1" >/dev/null 2>&1
}

preflight_checks() {
  log "Running preflight checks"

  if [ "$OS_TYPE" = "Linux" ] && [ "$IS_WSL" = "1" ] && ! require_command wslview; then
    log "WSL detected: browser handoff helper (wslview) missing now; it will be installed via wslu"
    log "If a browser login step appears before that, use the device URL/code manually"
  fi

  if [ -f "$HOME/.npmrc" ] && grep -Eq '^[[:space:]]*(prefix|globalconfig)[[:space:]]*=' "$HOME/.npmrc"; then
    log "Found npm prefix/globalconfig entries in ~/.npmrc; these will be cleaned before nvm use"
  fi

  if require_command gh; then
    local gh_version
    gh_version="$(gh --version | awk 'NR==1 {print $3}')"
    log "Detected gh version: $gh_version"
  fi

  if [ "$IS_WSL" = "1" ] && [ "$CONFIGURE_WT_SHIFT_ENTER" = "1" ]; then
    log "WSL detected: setup will try to configure Windows Terminal Shift+Enter newline"
  fi
}

find_windows_terminal_settings() {
  local settings_glob
  local settings_path
  settings_glob='/mnt/c/Users/*/AppData/Local/Packages/Microsoft.WindowsTerminal_8wekyb3d8bbwe/LocalState/settings.json'

  for settings_path in $settings_glob; do
    if [ -f "$settings_path" ]; then
      printf '%s\n' "$settings_path"
      return
    fi
  done
}

configure_windows_terminal_shift_enter() {
  if [ "$IS_WSL" != "1" ] || [ "$CONFIGURE_WT_SHIFT_ENTER" != "1" ]; then
    return
  fi

  local settings_path
  settings_path="$(find_windows_terminal_settings || true)"

  if [ -z "$settings_path" ]; then
    log "Windows Terminal settings not found; skipping Shift+Enter fix"
    return
  fi

  if ! require_command python3; then
    log "python3 not found; skipping automatic Shift+Enter fix"
    return
  fi

  local result
  result="$(python3 - "$settings_path" <<'PY'
import json
import sys
from pathlib import Path

settings_path = Path(sys.argv[1])
raw = settings_path.read_text(encoding="utf-8")

try:
    data = json.loads(raw)
except json.JSONDecodeError:
    print("json-parse-failed")
    sys.exit(0)

action_id = "User.sendNewLineInput"

actions = data.get("actions")
if not isinstance(actions, list):
    actions = []
    data["actions"] = actions

keybindings = data.get("keybindings")
if not isinstance(keybindings, list):
    keybindings = []
    data["keybindings"] = keybindings

shift_enter_binding = None
for entry in keybindings:
    if isinstance(entry, dict) and str(entry.get("keys", "")).lower() == "shift+enter":
        shift_enter_binding = entry
        break

if shift_enter_binding and shift_enter_binding.get("id") != action_id:
    print("shift-enter-in-use")
    sys.exit(0)

changed = False

if not any(isinstance(entry, dict) and entry.get("id") == action_id for entry in actions):
    actions.append({
        "command": {
            "action": "sendInput",
            "input": "\n",
        },
        "id": action_id,
    })
    changed = True

if shift_enter_binding is None:
    keybindings.append({
        "id": action_id,
        "keys": "shift+enter",
    })
    changed = True

if changed:
    settings_path.write_text(json.dumps(data, indent=4) + "\n", encoding="utf-8")
    print("updated")
else:
    print("already-set")
PY
)"

  case "$result" in
    updated)
      log "Configured Windows Terminal Shift+Enter newline: $settings_path"
      ;;
    already-set)
      log "Windows Terminal Shift+Enter newline already configured"
      ;;
    shift-enter-in-use)
      log "Shift+Enter is already bound in Windows Terminal; leaving existing binding unchanged"
      ;;
    json-parse-failed)
      log "Could not parse Windows Terminal settings.json; configure Shift+Enter manually"
      ;;
    *)
      log "Shift+Enter setup returned: $result"
      ;;
  esac
}

install_homebrew() {
  if require_command brew; then
    log "Homebrew already installed"
    return
  fi

  log "Installing Homebrew"
  NONINTERACTIVE=1 bash -c \
    "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
}

load_homebrew() {
  if require_command brew; then
    return
  fi

  if [ -x /opt/homebrew/bin/brew ]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
    return
  fi

  if [ -x /usr/local/bin/brew ]; then
    eval "$(/usr/local/bin/brew shellenv)"
    return
  fi

  die "Homebrew install appears incomplete: brew not found"
}

ensure_macos_build_tools() {
  if xcode-select -p >/dev/null 2>&1; then
    log "Xcode Command Line Tools already installed"
    return
  fi

  log "Installing Xcode Command Line Tools"
  xcode-select --install >/dev/null 2>&1 || true

  until xcode-select -p >/dev/null 2>&1; do
    printf '.'
    sleep 5
  done

  printf '\n'
  log "Xcode Command Line Tools installed"
}

install_core_packages_apt() {
  local packages=(
    zsh
    git
    gh
    curl
    build-essential
    ripgrep
    fd-find
    bat
    bubblewrap
  )
  local missing=()

  if [ "$IS_WSL" = "1" ]; then
    packages+=(wslu)
  fi

  for pkg in "${packages[@]}"; do
    if ! apt_pkg_installed "$pkg"; then
      missing+=("$pkg")
    fi
  done

  if [ "${#missing[@]}" -eq 0 ]; then
    log "Core packages already installed"
    return
  fi

  log "Installing core packages with apt: ${missing[*]}"
  sudo apt-get update
  sudo apt-get install -y "${missing[@]}"

  if [ "$IS_WSL" = "1" ]; then
    log "WSL detected; browser bridge support is included via wslu"
  fi
}

install_brew_formula() {
  local formula="$1"

  if brew list --formula "$formula" >/dev/null 2>&1; then
    log "Homebrew formula already installed: $formula"
    return
  fi

  log "Installing Homebrew formula: $formula"
  brew install "$formula"
}

install_core_packages_brew() {
  local formulas=(
    zsh
    git
    gh
    curl
    ripgrep
    fd
    bat
  )
  local formula

  ensure_macos_build_tools
  install_homebrew
  load_homebrew

  for formula in "${formulas[@]}"; do
    install_brew_formula "$formula"
  done

  log "Skipping bubblewrap on macOS because it is not a standard supported dependency there"
}

install_core_packages() {
  case "$OS_TYPE" in
    Linux)
      install_core_packages_apt
      ;;
    Darwin)
      install_core_packages_brew
      ;;
    *)
      die "Unsupported operating system: $OS_TYPE"
      ;;
  esac
}

install_oh_my_zsh() {
  if [ -d "$OH_MY_ZSH_DIR" ]; then
    log "Oh My Zsh already installed"
    return
  fi

  log "Installing Oh My Zsh"
  RUNZSH=no CHSH=no KEEP_ZSHRC=yes sh -c \
    "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
}

install_powerlevel10k() {
  if [ -d "$P10K_DIR" ]; then
    log "powerlevel10k already installed"
    return
  fi

  log "Installing powerlevel10k"
  git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$P10K_DIR"
}

install_nvm() {
  if [ -s "$NVM_DIR/nvm.sh" ]; then
    log "NVM already installed"
    return
  fi

  log "Installing NVM"
  curl -fsSL https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash
}

sanitize_npm_prefix_conflicts() {
  log "Checking npm and nvm compatibility"

  remove_pattern_from_file "$HOME/.npmrc" '^[[:space:]]*(prefix|globalconfig)[[:space:]]*=' 'pre-dev-setup'
  remove_pattern_from_file "$BASHRC_TARGET" '[.]npm-global/bin' 'pre-dev-setup'
  remove_pattern_from_file "$ZSHRC_TARGET" '[.]npm-global/bin' 'pre-dev-setup'

  unset npm_config_prefix NPM_CONFIG_PREFIX PREFIX

  if require_command npm; then
    npm config delete prefix >/dev/null 2>&1 || true
    npm config delete globalconfig >/dev/null 2>&1 || true
  fi
}

load_nvm() {
  export NVM_DIR="$NVM_DIR"

  if [ ! -s "$NVM_DIR/nvm.sh" ]; then
    die "NVM install appears incomplete: $NVM_DIR/nvm.sh not found"
  fi

  # shellcheck disable=SC1090
  . "$NVM_DIR/nvm.sh"
}

install_node_lts() {
  local current_default
  current_default="$(nvm version default 2>/dev/null || true)"

  log "Installing latest LTS Node via NVM"
  nvm install --lts
  nvm alias default 'lts/*' >/dev/null
  nvm use --delete-prefix default >/dev/null 2>&1 || true

  if [ "$current_default" = "N/A" ] || [ -z "$current_default" ]; then
    log "Default Node version set to latest LTS"
  else
    log "Default Node version updated to latest LTS"
  fi
}

install_codex() {
  if npm list -g --depth=0 @openai/codex >/dev/null 2>&1; then
    log "Codex already installed: @openai/codex"
    return
  fi

  log "Installing Codex: @openai/codex"
  npm install -g @openai/codex
}

create_project_directories() {
  local dirs=(
    "$HOME/projects/frontend"
    "$HOME/projects/python-trading"
  )

  for dir in "${dirs[@]}"; do
    if [ -d "$dir" ]; then
      log "Directory already exists: $dir"
    else
      log "Creating directory: $dir"
      mkdir -p "$dir"
    fi
  done
}

install_shared_shell_path() {
  mkdir -p "$DEV_SETUP_CONFIG_DIR"

  cat >"$SHARED_PATH_FILE" <<'EOF'
# Added by dev-setup: shared PATH entries.
if [ -d "$HOME/.opencode/bin" ]; then
  case ":$PATH:" in
    *":$HOME/.opencode/bin:"*) ;;
    *) PATH="$HOME/.opencode/bin:$PATH" ;;
  esac
fi

export PATH
EOF

  ensure_line_in_file "$BASHRC_TARGET" '[ -f "$HOME/.config/dev-setup/path.sh" ] && . "$HOME/.config/dev-setup/path.sh"'
  ensure_line_in_file "$ZSHRC_TARGET" '[ -f "$HOME/.config/dev-setup/path.sh" ] && . "$HOME/.config/dev-setup/path.sh"'
}

install_zshrc() {
  [ -f "$ZSHRC_SOURCE" ] || die "Missing source zshrc file at $ZSHRC_SOURCE"
  [ -f "$ZSHRC_APPEND_SOURCE" ] || die "Missing zsh append file at $ZSHRC_APPEND_SOURCE"

  if [ ! -f "$ZSHRC_TARGET" ]; then
    log "Installing new .zshrc to $ZSHRC_TARGET"
    cp "$ZSHRC_SOURCE" "$ZSHRC_TARGET"
    return
  fi

  local marker_start marker_end
  marker_start="# >>> dev-setup zsh additions >>>"
  marker_end="# <<< dev-setup zsh additions <<<"

  if grep -Fq "$marker_start" "$ZSHRC_TARGET"; then
    log ".zshrc already includes dev-setup additions"
    return
  fi

  backup_file_once "$ZSHRC_TARGET" "$HOME/.zshrc.pre-dev-setup"

  log "Appending dev-setup zsh additions to existing .zshrc"
  {
    printf '\n%s\n' "$marker_start"
    cat "$ZSHRC_APPEND_SOURCE"
    printf '%s\n' "$marker_end"
  } >>"$ZSHRC_TARGET"
}

set_default_shell_to_zsh() {
  local zsh_path
  zsh_path="$(command -v zsh || true)"

  [ -n "$zsh_path" ] || die "zsh is not installed"

  if [ "${SHELL:-}" = "$zsh_path" ]; then
    log "Default shell already set to zsh"
    return
  fi

  if [ "$SET_DEFAULT_SHELL" != "1" ]; then
    log "Skipping default shell change. Set SET_DEFAULT_SHELL=1 to switch to zsh"
    return
  fi

  log "Setting default shell to zsh"
  chsh -s "$zsh_path"
}

run_optional_mcp_setup() {
  if [ "$INSTALL_MCP" != "1" ]; then
    log "Skipping MCP setup. Set INSTALL_MCP=1 to enable it"
    return
  fi

  [ -x "$MCP_SETUP_SCRIPT" ] || die "Missing executable MCP setup script at $MCP_SETUP_SCRIPT"

  log "Running optional MCP setup"
  "$MCP_SETUP_SCRIPT"
}

run_optional_github_setup() {
  if [ "$SETUP_GITHUB" != "1" ]; then
    log "Skipping GitHub setup. Set SETUP_GITHUB=1 to enable it"
    return
  fi

  [ -x "$GITHUB_SETUP_SCRIPT" ] || die "Missing executable GitHub setup script at $GITHUB_SETUP_SCRIPT"

  log "Running optional GitHub setup"
  "$GITHUB_SETUP_SCRIPT"
}

print_post_setup_summary() {
  local shell_path shell_process node_version npm_version gh_version codex_path
  local ssh_check_output

  shell_path="${SHELL:-unknown}"
  shell_process="${0:-unknown}"
  node_version="$(node -v 2>/dev/null || printf 'missing')"
  npm_version="$(npm -v 2>/dev/null || printf 'missing')"
  gh_version="$(gh --version 2>/dev/null | awk 'NR==1 {print $3}' || printf 'missing')"
  codex_path="$(command -v codex 2>/dev/null || printf 'missing')"

  log "Post-setup verification"
  printf '%s\n' "- SHELL env: $shell_path"
  printf '%s\n' "- Current shell process: $shell_process"
  printf '%s\n' "- Node: $node_version"
  printf '%s\n' "- npm: $npm_version"
  printf '%s\n' "- gh: $gh_version"
  printf '%s\n' "- codex: $codex_path"

  ssh_check_output="$(ssh -T -o BatchMode=yes -o ConnectTimeout=5 git@github.com 2>&1 || true)"
  if printf '%s' "$ssh_check_output" | grep -qi 'successfully authenticated'; then
    printf '%s\n' "- GitHub SSH auth: OK"
  else
    printf '%s\n' "- GitHub SSH auth: not verified in non-interactive mode"
  fi
}

main() {
  require_sudo

  log "Starting development environment setup on $OS_TYPE"
  preflight_checks
  configure_windows_terminal_shift_enter
  install_core_packages
  install_oh_my_zsh
  install_powerlevel10k
  install_nvm
  sanitize_npm_prefix_conflicts
  load_nvm
  install_node_lts
  install_codex
  create_project_directories
  install_zshrc
  install_shared_shell_path
  set_default_shell_to_zsh
  run_optional_github_setup
  run_optional_mcp_setup
  print_post_setup_summary
  log "Setup complete"
  log "Restart your shell or run: exec zsh"
}

main "$@"
