---
name: add-mcp
description: Add a new MCP server to Claude Code configuration
disable-model-invocation: true
user-invocable: true
argument-hint: [server-name-or-url]
allowed-tools: Read, Write, Edit, Bash, WebSearch, WebFetch, AskUserQuestion, Glob, Grep
---

# Add MCP Server

You are helping the user add a new MCP server to their Claude Code configuration.

## Step 1: Identify the server

If `$ARGUMENTS` is provided, use it to find the MCP server (it may be a name, npm package, GitHub URL, or Docker image). Otherwise ask what MCP server they want to add.

Search for installation instructions:
- Check GitHub README for the server
- Check npm registry if it's an npm package
- Check Docker Hub / GHCR if it's a Docker image

## Step 2: Ask which level to add the server to

Use AskUserQuestion to ask:

**Question:** "Which level should this MCP server be added to?"

| Level | Description |
|-------|-------------|
| **User (recommended)** | Available across all projects. Stored in `~/.claude.json` under `projects.<current-project-path>.mcpServers` |
| **Global** | Available across all projects. Stored in `~/.claude/settings.json` under `mcpServers` |
| **Project** | Only this project. Stored in `.claude/mcp.json` in the project root |

Default recommendation: **User** level.

## Step 3: Determine the server type and build config

### npx-based servers
For npm packages, resolve the full path to npx to avoid PATH issues:
```bash
which npx
```
Use the **full absolute path** (e.g., `/opt/homebrew/opt/node@22/bin/npx`) in the command field.

Config format:
```json
{
  "type": "stdio",
  "command": "/full/path/to/npx",
  "args": ["-y", "package-name@latest", ...additional-args],
  "env": {}
}
```

### Docker-based servers
Pull the image first:
```bash
docker pull <image>
```

Config format:
```json
{
  "type": "stdio",
  "command": "docker",
  "args": ["run", "--rm", "-i", "-v", "/Users/david/source:/workspace", "<image>", "/workspace"],
  "env": {}
}
```

Adjust the volume mount as needed for the server's requirements.

### uv-based servers (Python)
Config format:
```json
{
  "command": "uv",
  "args": ["run", "--directory", "/path/to/server", "server-name"]
}
```

### Other (custom command)
Ask the user for the command and args.

## Step 4: Test the server

Before writing config, verify the server starts correctly by sending an MCP initialize request:
```bash
echo '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2024-11-05","capabilities":{},"clientInfo":{"name":"test","version":"0.1.0"}}}' | <command> <args> 2>&1
```

If it fails, diagnose and fix:
- **npx ENOTEMPTY**: Clear the npx cache (`rm -rf ~/.npm/_npx/<hash>`) and retry
- **Docker not running**: Tell user to start Docker Desktop
- **Command not found**: Resolve full path with `which`
- **Permission denied**: Check file permissions

## Step 5: Write the configuration

### User level (`~/.claude.json`)
This file is frequently updated by Claude Code itself. Use `python3 -c` for atomic JSON updates to avoid race conditions:

```bash
python3 -c "
import json
with open('$HOME/.claude.json', 'r') as f:
    data = json.load(f)

project_path = '<current-project-absolute-path>'
if project_path not in data.get('projects', {}):
    data.setdefault('projects', {})[project_path] = {'mcpServers': {}}

data['projects'][project_path].setdefault('mcpServers', {})['<server-name>'] = {
    'type': 'stdio',
    'command': '<command>',
    'args': [<args>],
    'env': {}
}

with open('$HOME/.claude.json', 'w') as f:
    json.dump(data, f, indent=2)
"
```

### Global level (`~/.claude/settings.json`)
Read the file, then use Edit to add the server under the `mcpServers` key.

### Project level (`.claude/mcp.json`)
Create or update `.claude/mcp.json` in the project root:
```json
{
  "mcpServers": {
    "<server-name>": { ... }
  }
}
```

## Step 6: Confirm

Tell the user:
1. The server was added successfully
2. They need to restart Claude Code (`/mcp` to verify after restart)
3. What tools/capabilities the server provides (if known from the README)
