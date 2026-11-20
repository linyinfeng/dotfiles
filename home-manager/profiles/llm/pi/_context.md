# Pi

- MCP servers in `~/.pi/agent/mcp.json` (`context7-mcp`, `exa`, `grep-app`,
  `mcp-nixos`, and when configured `mineru-open-mcp`) use `deferred` exposure
  and must be discovered via `tool_search` first.
- Prefer `mcp-nixos` over `nix search` for nixpkgs/NixOS/Home Manager lookups,
  and built-in `web_search` over `exa` for general web queries.
- `pi-lens` has self-installation disabled (`PI_LENS_DISABLE_*_INSTALL=1`); if
  a formatter, linter, or LSP reports `not-installed`, provide it via Nix
  rather than installing by hand. Do not manually re-run its startup scanners.
- For `pi-subagents` / `interactive_shell`, only `pi` and `codex` are
  installed; `claude` / `cursor-agent` binaries are absent.
- Only call `create_goal` when the user explicitly requests a goal; never
  promote an internal `todo` list into a persistent goal.
