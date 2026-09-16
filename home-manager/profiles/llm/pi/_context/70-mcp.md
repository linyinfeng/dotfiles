# MCP

- One MCP action → `mcp.<server>.<tool>`; a ref computed at runtime →
  `tools.call`. `extensions.mcp` is the adapter's own tool, not this surface.
- Structured, versioned library or API documentation → the `context7-mcp`
  server; the open web is `extensions.web_search` instead.
- Auth is manual by default: `extensions.mcp` with
  `action:auth-start`/`auth-complete`.
- MinerU writes extracted documents under `~/Data/Documents/MinerU`.
