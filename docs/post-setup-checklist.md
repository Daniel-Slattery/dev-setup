# Post-setup checklist

Use this after running `./setup.sh` on a new machine.

## Core tools

- `zsh --version`
- `git --version`
- `gh --version`
- `node --version`
- `npm --version`
- `codex --version`

## Shell setup

- `echo $SHELL`
- `test -d ~/.oh-my-zsh && echo oh-my-zsh-ok`
- `test -d ~/.oh-my-zsh/custom/themes/powerlevel10k && echo p10k-ok`
- `test -f ~/.zshrc && echo zshrc-ok`
- `test -f ~/.zshrc.pre-dev-setup && echo zshrc-backup-found`

## Node and NVM

- `command -v nvm`
- `nvm current`
- `nvm alias default`

## GitHub

- `gh auth status`
- `ssh -T git@github.com`

## WSL only

- `wslview https://github.com`
- verify browser-based OAuth opens in Windows

## Terminal behavior

- verify `Shift+Enter` inserts a newline in your terminal AI tool (auto-configured on WSL when possible)
- if needed, follow [`terminal-setup.md`](/home/daniel/dev-setup/docs/terminal-setup.md)

## Directories

- `test -d ~/projects/frontend && echo frontend-ok`
- `test -d ~/projects/python-trading && echo python-trading-ok`

## Optional layers

- if used, run `./modules/github.sh`
- if used, run `INSTALL_MCP=1 ./setup.sh` or `./modules/mcp.sh`

## Final step

- restart the shell with `exec zsh`
