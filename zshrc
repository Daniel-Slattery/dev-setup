export ZSH="$HOME/.oh-my-zsh"
export ZSH_THEME="powerlevel10k/powerlevel10k"
plugins=(git)

source "$ZSH/oh-my-zsh.sh"

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && . "$NVM_DIR/bash_completion"

load-nvmrc() {
  local node_version
  local nvmrc_path
  nvmrc_path="$(nvm_find_nvmrc)"

  if [ -n "$nvmrc_path" ]; then
    node_version="$(<"$nvmrc_path")"
    if [ "$(nvm version "$node_version")" = "N/A" ]; then
      nvm install "$node_version"
    fi
    nvm use --silent "$node_version" >/dev/null
  else
    local default_node
    default_node="$(nvm version default)"
    if [ "$default_node" != "N/A" ]; then
      nvm use --silent default >/dev/null
    fi
  fi
}

autoload -U add-zsh-hook
add-zsh-hook chpwd load-nvmrc
load-nvmrc

[ -x "$(command -v batcat)" ] && alias bat='batcat'
[ -x "$(command -v fdfind)" ] && alias fd='fdfind'

alias gs='git status -sb'
alias ga='git add'
alias gc='git commit'
alias gp='git push'
alias gl='git pull'
alias ll='ls -lah'
alias ..='cd ..'
alias ...='cd ../..'
alias cdp='cd ~/projects'
alias cdf='cd ~/projects/frontend'
alias cdt='cd ~/projects/python-trading'
