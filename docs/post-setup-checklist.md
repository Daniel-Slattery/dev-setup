# Post-setup checklist

Use this after running `./setup.sh`, `./profiles/work.sh`, or `./profiles/personal.sh` on a new machine.

## Core tools

- `zsh --version`
- `git --version`
- `gh --version`
- `pyenv --version`
- `python --version`
- `node --version`
- `npm --version`
- `opencode --version` (if you enabled OpenCode)

## Shell setup

- `echo $SHELL`
- `getent passwd "$USER" | cut -d: -f7` on Linux, or `dscl . -read /Users/$USER UserShell` on macOS
- `test -d ~/.oh-my-zsh && echo oh-my-zsh-ok`
- `test -d ~/.oh-my-zsh/custom/themes/powerlevel10k && echo p10k-ok`
- `test -f ~/.p10k.zsh && echo p10k-config-ok`
- `test -f ~/.zshrc && echo zshrc-ok`
- `test -f ~/.zshrc.pre-dev-setup && echo zshrc-backup-found`

## Node and NVM

- `command -v nvm`
- `nvm current`
- `nvm alias default`

## Python and pyenv

- `pyenv versions`
- `pyenv global`
- `python --version`

## GitHub

- `gh auth status`
- `ssh -T git@github.com`

## WSL only

- `wslview https://github.com`
- verify browser-based OAuth opens in Windows
- if prompt symbols still look wrong in Windows Terminal, install a Nerd Font on Windows and select it in your terminal profile

## Terminal behavior

- verify `Shift+Enter` inserts a newline in your terminal AI tool
- if needed, follow the relevant platform guide in `docs/platforms/`

## Directories

- `test -d ~/projects/frontend && echo frontend-ok`
- `test -d ~/projects/python-projects && echo python-projects-ok`

## Optional layers

- if used, run `./modules/github.sh`
- if used, run `INSTALL_MCP=1 ./setup.sh` or `./modules/mcp.sh`
- if used, copy the sample config from `config/mcp/` into your Copilot CLI or OpenCode config location

## Final step

- restart the shell with `exec zsh`
