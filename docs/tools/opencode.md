# OpenCode setup

OpenCode installation is optional in this repo and is enabled with:

```bash
INSTALL_OPENCODE=1 ./setup.sh
```

The personal profile enables that by default:

```bash
./profiles/personal.sh
```

## Example files in this repo

- `config/mcp/opencode.work.example.json`
- `config/mcp/opencode.personal.example.json`

## Suggested destination

By default, the setup now installs the personal example to:

```text
~/.config/opencode/opencode.json
```

If that file already exists, setup leaves it unchanged.

## What to change after install or copying

Replace:

- `REPLACE_WITH_GITHUB_TOKEN` with a real token if you enable the GitHub server
- `REPLACE_WITH_POSTGRES_CONNECTION_STRING` with a real connection string if you enable Postgres

The setup script replaces `/ABSOLUTE/PATH/TO/projects` with `$HOME/projects` automatically when it creates the file.

## Notes

- OpenCode config uses an `mcp` root object in the examples in this repo
- The shared shell PATH file already includes `~/.opencode/bin`
- If you want a richer prompt after installing OpenCode, install a Nerd Font and re-run `p10k configure`
