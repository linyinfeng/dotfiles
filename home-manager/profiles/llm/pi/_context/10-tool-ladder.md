# Pi tool ladder

Every capability is a ref inside one `fabric_exec` program: core tools as `pi.*`,
extension tools as `extensions.*`, MCP as `mcp.*`. Reach for the cheaper ref
first, and write one program per job instead of one call per step.

Escalate only when the cheaper rung cannot answer:

1. `pi.read`, `pi.grep`, `pi.find`, `pi.ls` — local, no process.
2. `extensions.symbol_search`, `extensions.module_report`,
   `extensions.read_symbol`, `extensions.read_enclosing` — local index, no process.
3. `extensions.lens_diagnostics`, `extensions.lsp_navigation` — starts/reuses a
   language server.
4. `extensions.fetch_content`, `extensions.get_search_content` — one request, no
   synthesis.
5. `extensions.web_search`, `extensions.source_check` — provider calls plus LLM
   synthesis.
6. `mcp.*` — spawns MCP servers.
7. `extensions.bg_run`, `extensions.subagent` — child process; a subagent also
   spends model tokens.
8. `extensions.interactive_shell` — a PTY behind a TUI overlay.
9. `extensions.agent_browser` — real browser process, artifacts on disk.
10. `extensions.fusion_*` — five model slots per call.
