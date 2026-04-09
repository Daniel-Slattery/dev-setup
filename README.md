# dev-setup

Reusable development bootstrap for WSL Ubuntu and macOS.

## Files

- `setup.sh`: idempotent setup script
- `zshrc`: base shell config used when `~/.zshrc` does not exist
- `zshrc.append`: additive zsh config appended to existing `~/.zshrc`
- `docs/post-setup-checklist.md`: final verification checklist
- `docs/terminal-setup.md`: terminal and OAuth follow-up notes
- `modules/github.sh`: optional GitHub bootstrap
- `modules/mcp.sh`: optional MCP bootstrap
- `config/mcp-servers.txt`: MCP server manifest
- `config/mcp.env.example`: MCP secrets template

## What it does

- Installs core packages with `apt` on Ubuntu and Homebrew on macOS
- Detects WSL and installs `wslu` for browser handoff support
- Runs preflight checks and warns about common WSL OAuth/browser gaps before install
- On WSL, attempts to configure Windows Terminal so `Shift+Enter` sends a newline
- Uses Xcode Command Line Tools on macOS as the `build-essential` equivalent
- Installs GitHub CLI `gh`
- Installs Oh My Zsh non-interactively
- Installs `powerlevel10k`
- Installs `nvm` if missing
- Removes npm prefix/globalconfig conflicts that break `nvm`
- Installs the latest LTS Node version and sets it as default
- Installs Codex via `npm install -g @openai/codex`
- Creates:
  - `~/projects/frontend`
  - `~/projects/python-trading`
- Installs shared PATH config at `~/.config/dev-setup/path.sh` and sources it from bash/zsh
- Copies `zshrc` only when `~/.zshrc` does not exist
- Appends managed additions to existing `~/.zshrc` instead of replacing it
- Backs up an existing `~/.zshrc` to `~/.zshrc.pre-dev-setup` before first append
- Optionally prepares GitHub SSH setup when `SETUP_GITHUB=1` is set
- Optionally installs MCP server packages and prints Codex registration commands when `INSTALL_MCP=1` is set

## Run on a new machine

1. Put this folder at `~/dev-setup`
2. Run:

```bash
cd ~/dev-setup
chmod +x setup.sh
./setup.sh
```

To enable the optional MCP layer:

```bash
cd ~/dev-setup
cp config/mcp.env.example config/mcp.env
$EDITOR config/mcp.env
INSTALL_MCP=1 ./setup.sh
```

Or run the MCP module directly:

```bash
cd ~/dev-setup
chmod +x modules/mcp.sh
./modules/mcp.sh
```

To enable the optional GitHub bootstrap:

```bash
cd ~/dev-setup
chmod +x modules/github.sh
SETUP_GITHUB=1 ./setup.sh
```

Or run the GitHub module directly:

```bash
cd ~/dev-setup
chmod +x modules/github.sh
./modules/github.sh
```

To switch the default login shell to `zsh` during setup:

```bash
cd ~/dev-setup
SET_DEFAULT_SHELL=1 ./setup.sh
```

## Codex handoff

The intended workflow on a new machine is:

1. Run the base bootstrap script
2. Let Codex finish the interactive or machine-specific setup

Use this prompt with Codex after the initial script run:

```text
I have already cloned ~/dev-setup and run ./setup.sh on this machine.

Please help me finish the remaining setup. Work step by step, check what is already installed, and only do what is still missing.

Priorities:
1. Verify zsh, Oh My Zsh, powerlevel10k, nvm, Node LTS, gh, and Codex
2. Verify my GitHub auth state and SSH setup
3. If this is WSL, verify browser-opening support for OAuth flows and fix it if needed
4. Help configure terminal multiline input behavior if needed
5. Verify project directories and any optional MCP setup
6. Summarize what was completed and what still requires manual action

Do not reinstall things unnecessarily. Prefer idempotent fixes and explain any manual approval steps before taking them.
```

This is useful because some steps are intentionally not fully automated:

- GitHub login and browser-based OAuth
- Terminal-specific keybinding configuration
- Secret-backed MCP server configuration
- Machine-specific verification and cleanup

For terminal-specific follow-up, see [`docs/terminal-setup.md`](/home/daniel/dev-setup/docs/terminal-setup.md).
For final verification, see [`docs/post-setup-checklist.md`](/home/daniel/dev-setup/docs/post-setup-checklist.md).

## GitHub structure

- `modules/github.sh` creates `~/.ssh` if needed
- Generates an `ed25519` SSH key only if one does not already exist
- Sets `gh` to use SSH for git operations
- Prints the public key and next-step auth instructions
- Does not silently authenticate your GitHub account

## MCP structure

- `modules/mcp.sh` is intentionally separate from the base machine bootstrap
- `config/mcp-servers.txt` is the declarative server list
- `config/mcp.env` is ignored by git and holds secrets
- The current MCP module installs package dependencies and prints the exact `codex mcp add ...` commands to run for each server
- Secret-backed servers are safe to skip until their environment variables are populated

## Notes

- Safe to re-run
- Re-running will also refresh Node to the current LTS release and set it as the default
- Requires `sudo`
- On macOS, `bubblewrap` is skipped because it is not a standard supported dependency there
- On macOS, Xcode Command Line Tools installation can require brief user interaction before the script continues
- GitHub setup is opt-in and disabled by default
- MCP setup is opt-in and disabled by default
- Default shell switching is opt-in and disabled by default
- Windows Terminal `Shift+Enter` mapping can be disabled with `CONFIGURE_WT_SHIFT_ENTER=0`
- After completion, restart the shell or run:

```bash
exec zsh
```

## Recommended WSL setup

For a personal WSL development machine that will be used with AI-assisted tooling, passwordless `sudo` for your Linux user is the practical setup. It avoids repeated prompts during package installs and other privileged setup steps.

Create a dedicated sudoers rule:

```bash
sudo visudo -f /etc/sudoers.d/daniel
```

Add:

```sudoers
daniel ALL=(ALL) NOPASSWD: ALL
```

Verify it:

```bash
sudo -k
sudo whoami
```

This should print `root` without prompting for your password.
