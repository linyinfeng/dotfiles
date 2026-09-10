# Environment invariants

- Built-ins enabled: `read`, `bash`, `edit`, `write`. `grep`, `find` and `ls`
  exist but are not enabled, so text search runs through `bash` (`rg`),
  `symbol_search` or `ast_grep_search`.
- pi-lens's six situational tools — `ast_grep_search`, `ast_grep_replace`,
  `ast_grep_outline`, `ast_grep_dump`, `lsp_navigation`, `lens_diagnostic_mark`
  — register inactive. `pi_lens_activate_tools` activates them, and they are
  callable only on the next turn; activation is additive and never reverses.
  Never activate a tool and call it in the same turn — use `bash` instead when
  this turn cannot wait.
- `context_report` is off, and `agent_browser_web_search` is registered only
  when an Exa or Brave key exists; it is absent here.
- Subagents `claude-code`, `claude-code-writer`, `cursor-agent` and
  `cursor-agent-writer` need the `claude`/`cursor-agent` binaries, which are not
  installed; `codex-exec` and `codex-exec-writer` are available.
- Formatters, linters and language servers are never self-installed here
  (`PI_LENS_DISABLE_TOOL_INSTALL`, `PI_LENS_DISABLE_LSP_INSTALL` are set), so a
  missing one reports `not-installed`; install it through nix, never by hand.
- pi-lens scans the project in the background at session start and merges at
  turn end (knip, jscpd, madge, gitleaks, govulncheck, dead-code, test-runner).
  trivy and the turn-end madge pass are opt-in and off — do not re-run any of
  them by hand.
- The five MCP servers (`context7-mcp`, `exa`, `grep.app`, `mcp-nixos`,
  `mineru-open-mcp`) connect lazily and their metadata is cached, so `search`
  and `describe` work with no live server.
