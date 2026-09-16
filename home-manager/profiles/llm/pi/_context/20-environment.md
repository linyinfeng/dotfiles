# Environment invariants

- This harness runs pi-fabric's full code mode, so every tool named in these
  files is a ref inside `fabric_exec`: `pi.*` for core tools, `extensions.*` for
  extension tools, `mcp.*` for servers.
- An extension ref resolves to `{content, text, details, isError, terminate,
source}`; the tool's own payload is on `.text` or inside `.content`.
- `fullCodeMode` and `capture.keepVisible` apply live from `/fabric settings`. If
  a captured tool turns out to be callable directly, that is why — call it
  directly.
- pi-lens's five situational tools — `ast_grep_search`, `ast_grep_replace`,
  `ast_grep_outline`, `lsp_navigation`, `lens_diagnostic_mark` — register
  inactive. `extensions.pi_lens_activate_tools` activates them, and they are
  callable only on the next turn; activation is additive and never reverses.
- Two retired pi-lens names are not tools here: `lsp_diagnostics` folded into
  `lens_diagnostics`, whose `source` and `scope` select the analyzer, and
  `ast_grep_dump` folded into `ast_grep_search` with `dump=true`.
- `pi-interactive-shell` adds `interactive_shell` (active, not deferred) plus the
  `/spawn`, `/attach` and `/dismiss` commands; its config file is optional and
  unset here. Spawn agents resolve through the `pi`, `codex`, `claude` and cursor
  `agent` binaries, so only `pi` and `codex` are spawnable here; PTY support is
  experimental on Linux.
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
