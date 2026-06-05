# Dev Tools Reference

A profile-aware reference for the CLIs and MCP servers used across work and personal setups.

- [CLI Tools](#cli-tools)
- [MCP Servers — Work profile](#mcp-servers--work-profile)
- [MCP Servers — Personal profile](#mcp-servers--personal-profile)
- [Notes](#notes)

---

## CLI Tools

### Core tools (all setups)

Installed automatically by `setup.sh` via `apt` on Ubuntu/WSL or Homebrew on macOS.

| Tool | Purpose |
| --- | --- |
| `zsh` | Shell |
| `git` | Version control |
| `gh` | GitHub CLI — auth, PRs, issues, releases |
| `nvm` | Node version manager |
| `node` / `npm` | JavaScript runtime (installed via nvm) |
| `pyenv` | Python version manager |
| `python` | Python runtime (installed via pyenv) |
| `ripgrep` (`rg`) | Fast content search |
| `fd` | Fast file finder |
| `bat` | `cat` with syntax highlighting |

### AI and dev tooling (opt-in)

These are not installed by the base setup. See the install commands below.

| Tool | Install | Purpose |
| --- | --- | --- |
| `opencode` | `curl -fsSL https://opencode.ai/install \| bash` | AI coding agent. Enabled in the personal profile with `INSTALL_OPENCODE=1`. |
| `playwright-cli` | `npm install -g @playwright/cli` | Token-efficient browser automation for AI agents. Preferred over the MCP server for large-codebase sessions — see [Notes](#playwright-cli-vs-playwrightmcp). |

---

## MCP Servers — Work profile

These servers are configured in `~/.config/opencode/opencode.json` for an OpenCode work setup.

For Copilot CLI, the equivalent config goes in `~/.copilot/mcp-config.json` using the `mcpServers` format — see the [example files](../../config/mcp/) in this repo and the [notes on remote servers](#remote-servers-and-copilot-cli).

### atlassian

Provides access to Jira and Confluence via Atlassian's hosted MCP endpoint.

- **Source:** Remote — `https://mcp.atlassian.com/v1/mcp`
- **Auth:** Browser OAuth on first use (no static token required)
- **Env vars:** None

```json
"atlassian": {
  "type": "remote",
  "url": "https://mcp.atlassian.com/v1/mcp",
  "enabled": true
}
```

### github

Access to GitHub repos, issues, pull requests, and code search.

- **Source:** `@modelcontextprotocol/server-github`
- **Env vars:** `GITHUB_PERSONAL_ACCESS_TOKEN`

```json
"github": {
  "type": "local",
  "command": ["npx", "-y", "@modelcontextprotocol/server-github"],
  "enabled": true,
  "environment": {
    "GITHUB_PERSONAL_ACCESS_TOKEN": "REPLACE_WITH_GITHUB_TOKEN"
  }
}
```

### fable

Sainsbury's Fable design system — component props, tokens, and usage guidance.

- **Source:** `@sainsburys-tech/fable-mcp` (private npm registry)
- **Registry:** `https://npm.pkg.github.com` — requires `@sainsburys-tech:registry` in `~/.npmrc` and a scoped GitHub token with `read:packages` scope. See [Sainsbury's private npm registry](#sainsburys-private-npm-registry).
- **Env vars:** None (auth is via `.npmrc`)

```json
"fable": {
  "type": "local",
  "command": [
    "npx",
    "-y",
    "--@sainsburys-tech:registry=https://npm.pkg.github.com",
    "@sainsburys-tech/fable-mcp@latest"
  ],
  "enabled": true
}
```

### figma

Inspect Figma designs — layers, components, styles, and measurements.

- **Source:** Local proxy at `http://127.0.0.1:3845/mcp` served by the Figma desktop app
- **Requirement:** Figma desktop must be running with **Dev Mode MCP** enabled (Settings → Dev Mode → Enable MCP server). See [Figma local proxy](#figma-local-proxy).
- **Env vars:** None

```json
"figma": {
  "type": "remote",
  "url": "http://127.0.0.1:3845/mcp",
  "enabled": true
}
```

### context7

Fetches up-to-date library documentation and code examples for any framework or package.

- **Source:** Remote — `https://mcp.context7.com/mcp`
- **Env vars:** None

```json
"context7": {
  "type": "remote",
  "url": "https://mcp.context7.com/mcp",
  "enabled": true
}
```

### playwright

Browser automation via structured MCP tool calls. See [playwright-cli vs @playwright/mcp](#playwright-cli-vs-playwrightmcp) for when to use this vs the CLI.

- **Source:** `@playwright/mcp`
- **Env vars:** None

```json
"playwright": {
  "type": "local",
  "command": ["npx", "-y", "@playwright/mcp@latest"],
  "enabled": true
}
```

### newrelic

Observability — query dashboards, alerts, and logs from New Relic.

- **Source:** Remote — `https://mcp.newrelic.com/mcp` (OAuth)
- **Auth:** OAuth — requires a New Relic OAuth client ID. See your team's shared credentials or request one from the platform team.
- **Env vars:** None (auth handled via OAuth flow)

```json
"newrelic": {
  "type": "remote",
  "url": "https://mcp.newrelic.com/mcp",
  "oauth": {
    "clientId": "REPLACE_WITH_NEWRELIC_CLIENT_ID",
    "scope": "openid"
  },
  "enabled": true
}
```

---

## MCP Servers — Personal profile

### github

Same as the work profile. See [github](#github) above.

### obsidian

Read and write files in your Obsidian vault using the filesystem MCP server.

- **Source:** `@modelcontextprotocol/server-filesystem`
- **Env vars:** None (path configured directly)

```json
"obsidian": {
  "type": "local",
  "command": [
    "npx",
    "-y",
    "@modelcontextprotocol/server-filesystem",
    "REPLACE_WITH_OBSIDIAN_VAULT_PATH"
  ],
  "enabled": true
}
```

Replace `REPLACE_WITH_OBSIDIAN_VAULT_PATH` with the absolute path to your vault, e.g. `~/Documents/Obsidian Vault`.

### filesystem

General read/write access to a local projects directory.

- **Source:** `@modelcontextprotocol/server-filesystem`
- **Env vars:** None

```json
"filesystem": {
  "type": "local",
  "command": [
    "npx",
    "-y",
    "@modelcontextprotocol/server-filesystem",
    "REPLACE_WITH_PROJECTS_PATH"
  ],
  "enabled": true
}
```

### memory

Persistent key-value memory that survives across sessions.

- **Source:** `@modelcontextprotocol/server-memory`
- **Env vars:** None

```json
"memory": {
  "type": "local",
  "command": ["npx", "-y", "@modelcontextprotocol/server-memory"],
  "enabled": true
}
```

### context7

Same as the work profile. See [context7](#context7) above.

### playwright

Same as the work profile. See [playwright](#playwright) above.

### postgres

Query local PostgreSQL databases.

- **Source:** `@modelcontextprotocol/server-postgres`
- **Env vars:** `POSTGRES_CONNECTION_STRING`

```json
"postgres": {
  "type": "local",
  "command": ["npx", "-y", "@modelcontextprotocol/server-postgres"],
  "enabled": false,
  "environment": {
    "POSTGRES_CONNECTION_STRING": "REPLACE_WITH_POSTGRES_CONNECTION_STRING"
  }
}
```

---

## Notes

### `playwright-cli` vs `@playwright/mcp`

Both let an AI agent control a browser, but they work differently:

| | `playwright-cli` | `@playwright/mcp` |
| --- | --- | --- |
| **Best for** | Coding sessions with large codebases | Exploratory automation |
| **How it works** | Agent runs shell commands | Agent calls MCP tools with structured parameters |
| **Token cost** | Lower — concise CLI output, skills loaded on demand | Higher — tool schemas live in context permanently |
| **Default mode** | Headless | Headed |
| **Install** | `npm install -g @playwright/cli` | `npx -y @playwright/mcp@latest` (via MCP config) |

For long coding sessions where context window size matters, prefer `playwright-cli`. The MCP server is more convenient for standalone automation tasks where you want richer tool integration without loading a skill.

### Figma local proxy

The Figma MCP server is not a standalone package — it is built into the Figma desktop app. To enable it:

1. Open Figma desktop
2. Go to **Settings → Dev Mode**
3. Enable **MCP Server**

The app then serves the MCP endpoint at `http://127.0.0.1:3845/mcp`. If Figma is not running, this server is unavailable.

### Sainsbury's private npm registry

`@sainsburys-tech` packages (including `fable-mcp`) are published to GitHub's npm registry. To install them you need:

1. A GitHub personal access token with `read:packages` scope
2. The following in `~/.npmrc`:

```
@sainsburys-tech:registry=https://npm.pkg.github.com
//npm.pkg.github.com/:_authToken=YOUR_GITHUB_TOKEN
```

The `npx` command in the fable config passes `--@sainsburys-tech:registry=...` inline, so you can also scope it to just that invocation rather than a global `.npmrc` entry.

### Remote servers and Copilot CLI

OpenCode supports `"type": "remote"` for servers like `atlassian`, `context7`, and `newrelic`. Copilot CLI's current JSON config format (`mcpServers`) only supports `stdio`-based local servers — remote MCP endpoints are not configurable via the JSON file and must be set up through the CLI's interactive flow instead.

### Config file locations

| Tool | Config location |
| --- | --- |
| OpenCode | `~/.config/opencode/opencode.json` |
| Copilot CLI | `~/.copilot/mcp-config.json` (or `.copilot/mcp-config.json` per repo) |

Example config files for both tools and both profiles are in [`config/mcp/`](../../config/mcp/).
