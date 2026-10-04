# NixOS Rules

- **NixOS, immutable** — the base PATH is minimal; everything installs via Nix,
  never into the system with `apt`/`yum`/`dnf`/`pacman`, `make install`, or
  `curl | sh`.
- **Never** root-scoped searches (`find /`, `grep -r /`, `fd /`, `rg /`) —
  `/nix/store` is huge and traversing `/` hangs. Scope to directories; for system
  files use `which`/`whereis`/`nix-locate`.
- Ephemeral tools: `nix shell nixpkgs#<pkg> -c <cmd>`, or
  `nix run nixpkgs#<pkg> -- <args>`, several at once in one `nix shell`.
  Python: `nix shell nixpkgs#python3 nixpkgs#python3Packages.<pkg>`, never pip.
- Repo dev env: if `flake.nix`/`shell.nix` exists, `nix develop -c <cmd>` beats
  ad-hoc `nix shell`; a bare `nix develop` needs a TTY, so it cannot run
  non-interactively.
- This machine's dotfiles live in `~/Projects/dotfiles`; declarative changes
  belong there.

## This machine

- Built-in extensions are the four `builtin:<name>` ones: `mcp`, `llama.cpp`,
  `codemode`, `tool-search`. Here `codemode` comes from `defaultTools`,
  `tool-search` activates itself whenever a `deferred` MCP server connects, and
  `llama.cpp` contributes provider models only; `powershell` is Windows-only.
- The five MCP servers (`context7-mcp`, `exa`, `grep-app`, `mcp-nixos`,
  `mineru-open-mcp`, from `~/.pi/agent/mcp.json`) are pi's built-in MCP, all at
  `deferred` exposure. MinerU writes extracted documents under
  `~/Data/Documents/MinerU`.
- pi-lens's situational tools are inactive until `pi_lens_activate_tools` runs,
  and its formatters, linters and language servers are never self-installed here,
  so a missing one reports `not-installed` — install it through nix, never by
  hand. Its scanners run in the background at session start and merge at turn
  end; do not re-run them by hand.
- `pi-subagents` may start with `subagent` already declared or behind
  `subagents_enable`, depending on the model: check your tool list before assuming
  a gate. Spawnable child binaries are `pi` and `codex`; the `claude-code` and
  `cursor-agent` subagents, and `interactive_shell`'s `claude` and cursor agents,
  need binaries that are not installed.
- `agent_browser_web_search` and `context_report` are not available here.
- A privileged command runs as `bash` through `run0` (or `pkexec`), which
  authenticates through the session's polkit agent; each authentication costs a
  password prompt, so batch all root work into one call. `sudo` here is
  `run0-sudo-shim`: `sudo -n` always fails, and a piped `sudo -S` password cannot
  work.
