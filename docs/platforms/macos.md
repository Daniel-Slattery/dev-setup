# macOS setup

Use this when the target machine is **macOS**.

## Recommended flow

```bash
git clone https://github.com/Daniel-Slattery/dev-setup.git ~/dev-setup
cd ~/dev-setup
./setup.sh
```

Or use a profile wrapper:

```bash
./profiles/work.sh
./profiles/personal.sh
```

`setup.sh` installs `pyenv`, then installs the latest stable Python release and sets it as the global default. Use `.python-version` files per repo when you want a project-specific Python version.

## What is macOS-specific

- `setup.sh` installs Homebrew if needed
- `setup.sh` waits for Xcode Command Line Tools when they are not already installed
- `bubblewrap` is skipped on macOS
- If Homebrew installs `zsh` outside the default shell list, the script now adds it to `/etc/shells` before calling `chsh`

## Terminal multiline input

For iTerm2, the multiline fix is terminal-side rather than shell-side.

Suggested approach:

1. Open iTerm2 settings
2. Go to `Profiles` -> `Keys`
3. Add a key mapping for `Shift+Enter`
4. Set the action to send a newline character

Exact UI wording varies by version, but the goal is simply to make `Shift+Enter` send `\n`.

## Fonts and prompt icons

The repo now installs an ASCII-safe powerlevel10k config by default, so shell setup does not depend on a Nerd Font.

If you want richer prompt icons:

1. Install a Nerd Font such as MesloLGS NF
2. Select it in your terminal profile
3. Run `p10k configure`

## Default shell

To switch the login shell to `zsh` during setup:

```bash
SET_DEFAULT_SHELL=1 ./setup.sh
```

The script now checks the actual login shell and handles Homebrew `zsh` paths more reliably.
