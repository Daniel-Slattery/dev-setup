#!/usr/bin/env bash
set -Eeuo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ZSHRC_SOURCE="$SCRIPT_DIR/zshrc"
ZSHRC_APPEND_SOURCE="$SCRIPT_DIR/zshrc.append"
ZSHRC_TARGET="$HOME/.zshrc"
BASHRC_TARGET="$HOME/.bashrc"
MCP_SETUP_SCRIPT="$SCRIPT_DIR/modules/mcp.sh"
GITHUB_SETUP_SCRIPT="$SCRIPT_DIR/modules/github.sh"
P10K_CONFIG_SOURCE="$SCRIPT_DIR/config/p10k/p10k.zsh"
P10K_CONFIG_TARGET="$HOME/.p10k.zsh"
OPENCODE_CONFIG_TEMPLATE="$SCRIPT_DIR/config/mcp/opencode.personal.example.json"
OPENCODE_CONFIG_DIR="$HOME/.config/opencode"
OPENCODE_CONFIG_TARGET="$OPENCODE_CONFIG_DIR/opencode.json"
NVM_DIR="${NVM_DIR:-$HOME/.nvm}"
PYENV_ROOT="${PYENV_ROOT:-$HOME/.pyenv}"
OH_MY_ZSH_DIR="${ZSH:-$HOME/.oh-my-zsh}"
P10K_DIR="${ZSH_CUSTOM:-$OH_MY_ZSH_DIR/custom}/themes/powerlevel10k"
DEV_SETUP_CONFIG_DIR="$HOME/.config/dev-setup"
SHARED_PATH_FILE="$DEV_SETUP_CONFIG_DIR/path.sh"
OS_TYPE="$(uname -s)"
INSTALL_MCP="${INSTALL_MCP:-0}"
SETUP_GITHUB="${SETUP_GITHUB:-0}"
SET_DEFAULT_SHELL="${SET_DEFAULT_SHELL:-0}"
INSTALL_OPENCODE="${INSTALL_OPENCODE:-0}"
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

refresh_sudo_credentials() {
  log "Refreshing sudo credentials"
  sudo -v
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

write_file_if_changed() {
  local target="$1"
  local tmp_file
  tmp_file="$(mktemp)"
  cat >"$tmp_file"

  if [ -f "$target" ] && cmp -s "$tmp_file" "$target"; then
    rm -f "$tmp_file"
    return
  fi

  mv "$tmp_file" "$target"
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

  refresh_sudo_credentials
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
    make
    libssl-dev
    zlib1g-dev
    libbz2-dev
    libreadline-dev
    libsqlite3-dev
    libffi-dev
    liblzma-dev
    xz-utils
    tk-dev
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
    openssl
    readline
    sqlite
    xz
    zlib
    tcl-tk
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

install_p10k_config() {
  [ -f "$P10K_CONFIG_SOURCE" ] || die "Missing powerlevel10k config at $P10K_CONFIG_SOURCE"

  if [ -f "$P10K_CONFIG_TARGET" ]; then
    log "powerlevel10k config already exists: $P10K_CONFIG_TARGET"
    return
  fi

  log "Installing managed powerlevel10k config to $P10K_CONFIG_TARGET"
  cp "$P10K_CONFIG_SOURCE" "$P10K_CONFIG_TARGET"
}

install_nvm() {
  if [ -s "$NVM_DIR/nvm.sh" ]; then
    log "NVM already installed"
    return
  fi

  log "Installing NVM"
  curl -fsSL https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash
}

install_pyenv() {
  if [ -x "$PYENV_ROOT/bin/pyenv" ]; then
    log "pyenv already installed"
    return
  fi

  log "Installing pyenv"
  curl -fsSL https://pyenv.run | bash
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

load_pyenv() {
  export PYENV_ROOT="$PYENV_ROOT"

  if [ ! -x "$PYENV_ROOT/bin/pyenv" ]; then
    die "pyenv install appears incomplete: $PYENV_ROOT/bin/pyenv not found"
  fi

  case ":$PATH:" in
    *":$PYENV_ROOT/bin:"*) ;;
    *) PATH="$PYENV_ROOT/bin:$PATH" ;;
  esac

  case ":$PATH:" in
    *":$PYENV_ROOT/shims:"*) ;;
    *) PATH="$PYENV_ROOT/shims:$PATH" ;;
  esac

  export PATH
  eval "$(pyenv init - bash)"
}

latest_pyenv_python_version() {
  pyenv install --list | awk '
    /^[[:space:]]*[0-9]+\.[0-9]+\.[0-9]+[[:space:]]*$/ {
      gsub(/^[[:space:]]+|[[:space:]]+$/, "", $0)
      version = $0
    }
    END {
      if (version != "") {
        print version
      }
    }
  '
}

install_latest_python_with_pyenv() {
  local latest_python
  latest_python="$(latest_pyenv_python_version)"

  [ -n "$latest_python" ] || die "Could not determine latest stable Python version from pyenv"

  if pyenv versions --bare | grep -Fxq "$latest_python"; then
    log "Latest stable Python already installed via pyenv: $latest_python"
  else
    log "Installing latest stable Python via pyenv: $latest_python"
    pyenv install "$latest_python"
  fi

  pyenv global "$latest_python"
  log "Default Python version set via pyenv: $latest_python"
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

find_opencode_binary() {
  if require_command opencode; then
    command -v opencode
    return
  fi

  if [ -x "$HOME/.opencode/bin/opencode" ]; then
    printf '%s\n' "$HOME/.opencode/bin/opencode"
  fi
}

install_opencode() {
  if [ "$INSTALL_OPENCODE" != "1" ]; then
    log "Skipping OpenCode install. Set INSTALL_OPENCODE=1 to enable it"
    return
  fi

  if [ -n "$(find_opencode_binary || true)" ]; then
    log "OpenCode already installed"
    return
  fi

  log "Installing OpenCode"
  curl -fsSL https://opencode.ai/install | bash
}

install_opencode_config() {
  if [ "$INSTALL_OPENCODE" != "1" ]; then
    return
  fi

  [ -f "$OPENCODE_CONFIG_TEMPLATE" ] || die "Missing OpenCode config template at $OPENCODE_CONFIG_TEMPLATE"

  mkdir -p "$OPENCODE_CONFIG_DIR"

  if [ -f "$OPENCODE_CONFIG_TARGET" ]; then
    log "OpenCode config already exists: $OPENCODE_CONFIG_TARGET"
    return
  fi

  log "Installing default OpenCode config to $OPENCODE_CONFIG_TARGET"
  awk -v projects_path="$HOME/projects" '{
    gsub("/ABSOLUTE/PATH/TO/projects", projects_path)
    print
  }' "$OPENCODE_CONFIG_TEMPLATE" >"$OPENCODE_CONFIG_TARGET"

  if grep -Fq 'REPLACE_WITH_GITHUB_TOKEN' "$OPENCODE_CONFIG_TARGET"; then
    log "Update GITHUB_PERSONAL_ACCESS_TOKEN in $OPENCODE_CONFIG_TARGET before using the GitHub MCP server"
  fi
}

create_project_directories() {
  local dirs=(
    "$HOME/projects/frontend"
    "$HOME/projects/python-projects"
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

  write_file_if_changed "$SHARED_PATH_FILE" <<'EOF'
# Added by dev-setup: shared PATH entries.
export PYENV_ROOT="${PYENV_ROOT:-$HOME/.pyenv}"
if [ -d "$PYENV_ROOT/bin" ]; then
  case ":$PATH:" in
    *":$PYENV_ROOT/bin:"*) ;;
    *) PATH="$PYENV_ROOT/bin:$PATH" ;;
  esac
fi

if [ -d "$PYENV_ROOT/shims" ]; then
  case ":$PATH:" in
    *":$PYENV_ROOT/shims:"*) ;;
    *) PATH="$PYENV_ROOT/shims:$PATH" ;;
  esac
fi

if [ -d "$HOME/.opencode/bin" ]; then
  case ":$PATH:" in
    *":$HOME/.opencode/bin:"*) ;;
    *) PATH="$HOME/.opencode/bin:$PATH" ;;
  esac
fi

export PATH
EOF

  ensure_line_in_file "$BASHRC_TARGET" '[ -f "$HOME/.config/dev-setup/path.sh" ] && . "$HOME/.config/dev-setup/path.sh"'
  ensure_line_in_file "$BASHRC_TARGET" 'command -v pyenv >/dev/null 2>&1 && eval "$(pyenv init - bash)"'
}

load_shared_shell_path() {
  if [ -f "$SHARED_PATH_FILE" ]; then
    # shellcheck disable=SC1090
    . "$SHARED_PATH_FILE"
  fi
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
    local tmp_file
    tmp_file="$(mktemp)"

    backup_file_once "$ZSHRC_TARGET" "$HOME/.zshrc.pre-dev-setup"

    awk -v marker_start="$marker_start" -v marker_end="$marker_end" -v append_file="$ZSHRC_APPEND_SOURCE" '
      $0 == marker_start {
        print
        while ((getline line < append_file) > 0) {
          print line
        }
        close(append_file)
        in_block = 1
        next
      }

      $0 == marker_end {
        in_block = 0
        print
        next
      }

      !in_block { print }
    ' "$ZSHRC_TARGET" >"$tmp_file"

    mv "$tmp_file" "$ZSHRC_TARGET"
    log "Refreshed dev-setup zsh additions"
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

get_login_shell() {
  if [ "$OS_TYPE" = "Darwin" ] && require_command dscl; then
    dscl . -read "/Users/$USER" UserShell 2>/dev/null | awk '{print $2}'
    return
  fi

  if require_command getent; then
    getent passwd "$USER" | cut -d: -f7
    return
  fi

  awk -F: -v user="$USER" '$1 == user {print $7}' /etc/passwd
}

ensure_zsh_listed_in_shells() {
  local zsh_path="$1"

  if grep -Fqx "$zsh_path" /etc/shells; then
    return
  fi

  log "Adding $zsh_path to /etc/shells"
  printf '%s\n' "$zsh_path" | sudo tee -a /etc/shells >/dev/null
}

set_default_shell_to_zsh() {
  local zsh_path
  local login_shell
  zsh_path="$(command -v zsh || true)"

  [ -n "$zsh_path" ] || die "zsh is not installed"

  login_shell="$(get_login_shell || true)"

  if [ "$login_shell" = "$zsh_path" ]; then
    log "Default shell already set to zsh"
    return
  fi

  if [ "$SET_DEFAULT_SHELL" != "1" ]; then
    log "Skipping default shell change. Set SET_DEFAULT_SHELL=1 to switch to zsh"
    return
  fi

  log "Setting default shell to zsh"

  if [ "$OS_TYPE" = "Darwin" ]; then
    ensure_zsh_listed_in_shells "$zsh_path"
  fi

  sudo chsh -s "$zsh_path" "$USER"
}

run_optional_mcp_setup() {
  if [ "$INSTALL_MCP" != "1" ]; then
    log "Skipping MCP server setup. Set INSTALL_MCP=1 to enable it"
    return
  fi

  [ -x "$MCP_SETUP_SCRIPT" ] || die "Missing executable MCP server setup script at $MCP_SETUP_SCRIPT"

  log "Running optional MCP server setup"
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
  local shell_path shell_process login_shell node_version npm_version gh_version python_version pyenv_version opencode_path
  local ssh_check_output

  shell_path="${SHELL:-unknown}"
  shell_process="${0:-unknown}"
  login_shell="$(get_login_shell || printf 'unknown')"
  node_version="$(node -v 2>/dev/null || printf 'missing')"
  npm_version="$(npm -v 2>/dev/null || printf 'missing')"
  gh_version="$(gh --version 2>/dev/null | awk 'NR==1 {print $3}' || printf 'missing')"
  python_version="$(python --version 2>/dev/null || printf 'missing')"
  pyenv_version="$(pyenv --version 2>/dev/null || printf 'missing')"
  opencode_path="$(find_opencode_binary || printf 'missing')"

  log "Post-setup verification"
  printf '%s\n' "- SHELL env: $shell_path"
  printf '%s\n' "- Login shell: $login_shell"
  printf '%s\n' "- Current shell process: $shell_process"
  printf '%s\n' "- Python: $python_version"
  printf '%s\n' "- pyenv: $pyenv_version"
  printf '%s\n' "- Node: $node_version"
  printf '%s\n' "- npm: $npm_version"
  printf '%s\n' "- gh: $gh_version"
  printf '%s\n' "- opencode: $opencode_path"

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
  install_p10k_config
  install_nvm
  sanitize_npm_prefix_conflicts
  load_nvm
  install_node_lts
  install_pyenv
  load_pyenv
  install_latest_python_with_pyenv
  create_project_directories
  install_shared_shell_path
  load_shared_shell_path
  install_zshrc
  install_opencode
  install_opencode_config
  set_default_shell_to_zsh
  run_optional_github_setup
  run_optional_mcp_setup
  print_post_setup_summary
  log "Setup complete"
  log "Restart your shell or run: exec zsh"
}

main "$@"
