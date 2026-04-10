# Personal profile

Use the personal profile when you want the base machine bootstrap plus personal-tooling defaults.

## Run it

```bash
cd ~/dev-setup
./profiles/personal.sh
```

## What it enables by default

- `SETUP_GITHUB=1`
- `INSTALL_MCP=0`
- `INSTALL_OPENCODE=1`

That keeps the personal path focused on:

- GitHub SSH setup
- OpenCode installation
- Optional MCP setup only when you actually want it

## Typical next steps

1. Complete `gh auth login` if needed
2. Copy `config/mcp/opencode.personal.example.json`
3. Replace placeholder paths and any token values
4. Save it to `~/.config/opencode/opencode.json`

If you also want Codex MCP servers on this machine, run:

```bash
INSTALL_MCP=1 ./setup.sh
```

See:

- [OpenCode setup](../tools/opencode.md)
- [WSL notes](../platforms/wsl.md)
- [macOS notes](../platforms/macos.md)
