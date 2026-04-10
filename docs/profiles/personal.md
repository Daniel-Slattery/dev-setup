# Personal profile

Use the personal profile when you want the base machine bootstrap plus personal-tooling defaults.

## Run it

```bash
cd ~/dev-setup
./profiles/personal.sh
```

## What it enables by default

- `SETUP_GITHUB=1`
- `INSTALL_MCP=1`
- `INSTALL_OPENCODE=1`

That keeps the personal path focused on:

- GitHub SSH setup
- OpenCode installation
- MCP server package setup for local tooling

## Typical next steps

1. Complete `gh auth login` if needed
2. Review `~/.config/opencode/opencode.json`
3. Replace any token placeholders you want to enable

The personal profile now runs the optional MCP server package setup step by default and creates `~/.config/opencode/opencode.json` automatically when that file does not already exist.

See:

- [OpenCode setup](../tools/opencode.md)
- [WSL notes](../platforms/wsl.md)
- [macOS notes](../platforms/macos.md)
