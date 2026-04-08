# Terminal setup

This document covers terminal-specific configuration that is outside the scope of the base shell bootstrap.

## Windows Terminal

To make `Shift+Enter` insert a newline instead of submitting immediately in terminal-based AI tools, add a custom `sendInput` action to Windows Terminal.

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

Restart Windows Terminal after saving the file.

## WSL browser support

Browser-based OAuth flows from Linux tools inside WSL may fail if WSL cannot hand URLs off to Windows.

Install `wslu`:

```bash
sudo apt-get install -y wslu
```

Then test:

```bash
wslview https://github.com
```

If that works, tools such as `gh` are much less likely to get stuck trying to open a browser.

## iTerm2

For iTerm2, the equivalent fix is terminal-side key mapping rather than shell configuration.

Suggested approach:

1. Open iTerm2 settings
2. Go to `Profiles` -> `Keys`
3. Add a key mapping for `Shift+Enter`
4. Set the action to send a newline character

Exact UI wording can vary by iTerm2 version, but the goal is the same: make `Shift+Enter` send `\n` to the terminal app.

## Notes

- These settings are terminal-specific and should be documented rather than forced by `setup.sh`
- Not every terminal application handles multiline input the same way, but terminal key mapping is the first thing to fix
