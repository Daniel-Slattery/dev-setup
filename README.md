# dev-setup

Reusable development bootstrap for **macOS** and **WSL Ubuntu**, with separate guidance for **work** and **personal** setups.

## Start here

The repo is public, so GitHub auth is **not** required to clone it.

```bash
git clone https://github.com/Daniel-Slattery/dev-setup.git ~/dev-setup
cd ~/dev-setup
chmod +x setup.sh profiles/work.sh profiles/personal.sh
./setup.sh
```

If you already know the profile you want, use one of the wrappers instead:

```bash
./profiles/work.sh
./profiles/personal.sh
```

To switch the default login shell to `zsh` during setup:

```bash
SET_DEFAULT_SHELL=1 ./setup.sh
```

## Repo layout

| Path | Purpose |
| --- | --- |
| `setup.sh` | Base machine bootstrap shared by every setup |
| `profiles/work.sh` | Work-oriented wrapper around `setup.sh` |
| `profiles/personal.sh` | Personal-oriented wrapper around `setup.sh` |
| `modules/github.sh` | Optional GitHub SSH and `gh` bootstrap |
| `modules/mcp.sh` | Optional MCP package/bootstrap helper for Codex |
| `config/mcp/` | Example MCP config files for Copilot CLI and OpenCode |
| `config/p10k/p10k.zsh` | Managed powerlevel10k config copied to `~/.p10k.zsh` |
| `docs/platforms/` | macOS and WSL-specific notes |
| `docs/profiles/` | Work and personal setup guidance |
| `docs/tools/` | Tool-specific setup for Copilot CLI and OpenCode |

## What the base setup does

- Installs core packages with `apt` on Ubuntu and Homebrew on macOS
- Detects WSL and installs `wslu` for browser handoff support
- Tries to configure Windows Terminal so `Shift+Enter` sends a newline on WSL
- Uses Xcode Command Line Tools on macOS as the `build-essential` equivalent
- Installs GitHub CLI `gh`
- Installs Oh My Zsh non-interactively
- Installs `powerlevel10k`
- Installs a managed `~/.p10k.zsh` so the first-run wizard is skipped
- Installs `nvm` if missing
- Removes npm prefix/globalconfig conflicts that break `nvm`
- Installs the latest LTS Node version and sets it as default
- Installs Codex via `npm install -g @openai/codex`
- Optionally installs OpenCode when `INSTALL_OPENCODE=1`
- Creates:
  - `~/projects/frontend`
  - `~/projects/python-trading`
- Installs shared PATH config at `~/.config/dev-setup/path.sh`
- Copies `zshrc` only when `~/.zshrc` does not exist
- Appends managed additions to existing `~/.zshrc` instead of replacing it
- Optionally prepares GitHub SSH setup when `SETUP_GITHUB=1` is set
- Optionally installs MCP server packages and prints Codex registration commands when `INSTALL_MCP=1` is set

## Modules

`modules/` is just a repo convention for **optional setup layers**.

- `modules/github.sh` handles SSH key generation and `gh` SSH defaults
- `modules/mcp.sh` handles MCP package installation plus Codex registration commands

They are kept separate because they either depend on secrets, browser auth, or user-specific decisions.

## Pick the docs that match your machine

- [WSL notes](docs/platforms/wsl.md)
- [macOS notes](docs/platforms/macos.md)
- [Work profile](docs/profiles/work.md)
- [Personal profile](docs/profiles/personal.md)
- [Copilot CLI MCP setup](docs/tools/copilot-cli.md)
- [OpenCode setup](docs/tools/opencode.md)
- [Post-setup checklist](docs/post-setup-checklist.md)

## Notes

- Safe to re-run
- Re-running refreshes Node to the current LTS release and keeps it as default
- Requires `sudo`
- GitHub setup is opt-in and disabled by default
- MCP setup is opt-in and disabled by default
- OpenCode install is opt-in and disabled by default
- Default shell switching is opt-in and disabled by default
- Windows Terminal `Shift+Enter` mapping can be disabled with `CONFIGURE_WT_SHIFT_ENTER=0`
- Restart the shell after completion with `exec zsh`
