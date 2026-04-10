# Copilot CLI MCP setup

Copilot CLI uses JSON with an `mcpServers` root object.

## Example files in this repo

- `config/mcp/copilot-cli.work.example.json`
- `config/mcp/copilot-cli.personal.example.json`

## Suggested destination

Copy the file you want to:

```text
~/.copilot/mcp-config.json
```

You can also use a repo-local `.copilot/mcp-config.json` if you want project-specific config.

## What to change after copying

Replace:

- `/ABSOLUTE/PATH/TO/projects` with your real projects directory
- `REPLACE_WITH_GITHUB_TOKEN` with a real token if you enable the GitHub server
- `REPLACE_WITH_POSTGRES_CONNECTION_STRING` with a real connection string if you enable Postgres

## Notes

- Copilot CLI config uses `mcpServers`, not OpenCode's `mcp`
- The sample files are templates, not live config
- Keep secrets out of git-tracked files

If you prefer to add servers interactively, you can still use the CLI flow instead of copying the JSON directly.
