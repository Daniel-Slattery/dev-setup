# Work profile

Use the work profile when you want the base machine bootstrap plus work-oriented defaults.

## Run it

```bash
cd ~/dev-setup
./profiles/work.sh
```

## What it enables by default

- `SETUP_GITHUB=1`
- `INSTALL_MCP=1`
- `INSTALL_OPENCODE=0`

That keeps the work path focused on:

- GitHub SSH setup for private repos and `gh`
- MCP server package installation for local MCP workflows
- A conservative default that does not install OpenCode unless you opt in

## Typical next steps

1. Complete `gh auth login` if you are not already authenticated
2. Copy the relevant example from `config/mcp/copilot-cli.work.example.json`
3. Replace placeholder paths and tokens
4. Save it to `~/.copilot/mcp-config.json`

See:

- [Copilot CLI MCP setup](../tools/copilot-cli.md)
- [WSL notes](../platforms/wsl.md)
- [macOS notes](../platforms/macos.md)
