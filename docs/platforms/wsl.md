# WSL setup

Use this when the target machine is **WSL Ubuntu**.

## Recommended flow

```bash
git clone https://github.com/Daniel-Slattery/dev-setup.git ~/dev-setup
cd ~/dev-setup
./setup.sh
```

Or, if you want the work/personal defaults:

```bash
./profiles/work.sh
./profiles/personal.sh
```

## What is WSL-specific

- `setup.sh` installs `wslu` so Linux tools can open URLs in Windows
- `setup.sh` tries to configure Windows Terminal so `Shift+Enter` sends a newline
- Browser-based OAuth flows such as `gh auth login` should open in Windows once `wslview` works

## Browser handoff

Test this first if login flows behave strangely:

```bash
wslview https://github.com
```

If that opens in Windows, browser-based auth flows are much less likely to get stuck.

## Terminal setup

`setup.sh` tries to edit Windows Terminal `settings.json` automatically. If `Shift+Enter` still does not insert a newline, update Windows Terminal manually.

The settings file is usually here:

```text
%LOCALAPPDATA%\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json
```

Add this to the `actions` array:

```json
{
  "command": {
    "action": "sendInput",
    "input": "\n"
  },
  "id": "User.sendNewLineInput"
}
```

Add this to the `keybindings` array:

```json
{
  "id": "User.sendNewLineInput",
  "keys": "shift+enter"
}
```

## Fonts and prompt icons

The repo now installs an ASCII-safe powerlevel10k config by default, so missing Nerd Font glyphs should no longer block shell setup.

If you want richer prompt icons in Windows Terminal:

1. Install a Nerd Font on Windows, such as MesloLGS NF
2. Set that font in the Windows Terminal profile you use for WSL
3. Run `p10k configure` to switch from the bundled ASCII config to an icon-heavy one

If you see boxes or an unexpected symbol prompt during `p10k configure`, it is usually a font issue in Windows Terminal rather than inside Linux.

## Default shell

To change the login shell to `zsh` during setup:

```bash
SET_DEFAULT_SHELL=1 ./setup.sh
```

The script now uses the actual login shell entry instead of only checking `$SHELL`.

## Sudo

For a personal WSL development machine that will be used heavily with AI-assisted tooling, passwordless `sudo` for your Linux user can be practical.

Create a dedicated sudoers rule:

```bash
sudo visudo -f /etc/sudoers.d/$USER
```

Add:

```sudoers
your-user ALL=(ALL) NOPASSWD: ALL
```

Verify it:

```bash
sudo -k
sudo whoami
```
