# Obsidian MCP Setup

Run the interactive setup to connect Claude Code to your Obsidian vault.

## What This Does

1. Checks Node.js version (18+ required)
2. Installs MCP server dependencies
3. Guides you through enabling the required Obsidian plugins
4. Prompts for your Obsidian REST API key
5. Writes `.env` and registers the MCP server
6. Tests connections to Obsidian REST API and Omnisearch
7. Tells you whether to restart Claude Code

## Required Obsidian Plugins

- **Local REST API** — provides vault access over HTTP
- **Omnisearch** — provides full-text search (enable HTTP Server in its settings)

Both must be installed and Obsidian must be running for the MCP tools to work.

## Usage

```
/obsidian-setup
```

Claude will run `claude mcp add` to register the server, or run the interactive setup script:

```bash
node mcp-servers/obsidian/setup.js
```

## After Setup

Restart Claude Code. You will have access to these tools:

| Tool | Description |
|------|-------------|
| `obsidian_search` | Full-text search via Omnisearch |
| `obsidian_read` | Read a note by path |
| `obsidian_list` | List files in vault or a directory |
| `obsidian_append` | Append content to a note |
| `obsidian_patch` | Insert content under a heading |

## Re-running Setup

Safe to re-run at any time. Existing API key is preserved unless you paste a new one.

---

## Instructions for Claude

When this command is invoked on Linux, register the MCP server using `claude mcp add`:

```bash
claude mcp add \
  -e OBSIDIAN_API_KEY=<key from .env> \
  -e OBSIDIAN_HOST=127.0.0.1 \
  -e OBSIDIAN_PORT=27124 \
  -e OMNISEARCH_PORT=51361 \
  -e NODE_TLS_REJECT_UNAUTHORIZED=0 \
  -- obsidian node <project_root>/mcp-servers/obsidian/src/index.js
```

Note: on Linux, `mcpServers` in `~/.claude/settings.json` is NOT read by Claude Code. Use `claude mcp add` which writes to `~/.claude.json`. Verify with `claude mcp list`.

For interactive first-time setup (API key configuration), run:

```bash
node mcp-servers/obsidian/setup.js
```

After the script completes, remind the user to restart Claude Code for the MCP server to load.
