# Pi tool ladder

Escalate only when the cheaper rung cannot answer:

1. `read`, `read_symbol`, `read_enclosing`, `module_report` — local, no process.
2. `bash` (`rg`), `symbol_search`, `ast_grep_search` — local search, no tokens.
3. `lsp_navigation`, `lsp_diagnostics` — starts/reuses a language server.
4. `lens_diagnostics` `delta`/`all` (cache reads) → `full` (project sweep).
5. `fetch_content`, `get_search_content` — one request, no synthesis.
6. `web_search`, `source_check` — provider calls plus LLM synthesis.
7. `mcp` → `mcpScript` — spawns MCP servers; a script returns one result.
8. `bg_run`, `subagent` — child process; a subagent also spends model tokens.
9. `agent_browser` — real browser process, artifacts on disk.
10. `fusion_*` — five model slots per call.
