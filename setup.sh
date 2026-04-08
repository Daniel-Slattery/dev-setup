#!/usr/bin/env bash
set -Eeuo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ZSHRC_SOURCE="$SCRIPT_DIR/zshrc"
ZSHRC_TARGET="$HOME/.zshrc"
MCP_SETUP_SCRIPT="$SCRIPT_DIR/modules/mcp.sh"
GITHUB_SETUP_SCRIPT="$SCRIPT_DIR/modules/github.sh"
NVM_DIR="${NVM_DIR:-$HOME/.nvm}"
OH_MY_ZSH_DIR="${ZSH:-$HOME/.oh-my-zsh}"
P10K_DIR="${ZSH_CUSTOM:-$OH_MY_ZSH_DIR/custom}/themes/powerlevel10k"
OS_TYPE="$(uname -s)"
INSTALL_MCP="${INSTALL_MCP:-0}"
SETUP_GITHUB="${SETUP_GITHUB:-0}"

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

apt_pkg_installed() {
  dpkg -s "$1" >/dev/null 2>&1
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

install_zshrc() {
  [ -f "$ZSHRC_SOURCE" ] || die "Missing source zshrc file at $ZSHRC_SOURCE"

  if [ -f "$ZSHRC_TARGET" ] && cmp -s "$ZSHRC_SOURCE" "$ZSHRC_TARGET"; then
    log ".zshrc already up to date"
    return
  fi

  log "Installing .zshrc to $ZSHRC_TARGET"
  cp "$ZSHRC_SOURCE" "$ZSHRC_TARGET"
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

main() {
  require_sudo

  log "Starting development environment setup on $OS_TYPE"
  install_core_packages
  install_oh_my_zsh
  install_powerlevel10k
  install_nvm
  load_nvm
  install_node_lts
  install_codex
  create_project_directories
  install_zshrc
  run_optional_github_setup
  run_optional_mcp_setup
  log "Setup complete"
  log "Restart your shell or run: exec zsh"
}

main "$@"
