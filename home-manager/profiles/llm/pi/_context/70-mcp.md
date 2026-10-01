# MCP

- One MCP action → `mcp.<server>.<tool>`, with the names as declared. Where a
  name is not an identifier (`context7-mcp`, `grep.app`) use bracket access or
  the `_` alias, e.g. `mcp.context7_mcp.resolve_library_id`. A ref computed at
  runtime goes through `tools.call`.
- The servers are pi's built-in MCP, declared in `~/.pi/agent/mcp.json` at
  `deferred` exposure, so their `mcp__<server>__<tool>` tools are not declared to
  the model: they appear only after `tool_search`, while the fabric ref above
  needs no search.
- Managing servers is `/mcp` in the TUI, or `pi mcp list|add|remove|login|logout`
  from a shell. OAuth sign-in is manual (`pi mcp login <server>`).
- Structured, versioned library or API documentation → the `context7-mcp`
  server; the open web is `extensions.web_search` instead.
- MinerU writes extracted documents under `~/Data/Documents/MinerU`.
