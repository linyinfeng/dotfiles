# Local Environment

## System

- On NixOS, this machine's declarative configuration lives in
  `~/Projects/dotfiles`; never run root-scoped searches (`find /`, `grep -r /`,
  `fd /`, `rg /`) because `/nix/store` will hang traversal.
- In repositories with `flake.nix` or `shell.nix`, run tools with
  `nix develop -c <cmd>` (bare `nix develop` requires a TTY); otherwise use
  `nix shell nixpkgs#<pkg> -c <cmd>`.
- On Linux here, `sudo` is `run0-sudo-shim`: `sudo -n` always fails and piped
  `sudo -S` cannot work. Each privileged call (`run0` / `pkexec`) prompts via
  polkit, so batch root commands into a single invocation.

## Workspace & Git

- Source repositories live under `~/Projects/<repo>`. Read the local checkout
  first, clone there if missing, and treat non-target repos as read-only.
- Work in a git worktree rather than on the target branch:
  `git worktree add -b <topic> ~/Projects/worktrees/<repo>/<topic>`. Keep the
  target-branch checkout clean, keep branch and directory names identical, and
  commit/push from the worktree.
- Unless instructed otherwise, commit completed changes matching the repo's
  style without editing Git config:

  ```bash
  git -c user.name=Nano -c user.email=nano@linyinfeng.com commit \
    --trailer 'Co-authored-by: Lin Yinfeng <lin.yinfeng@outlook.com>' \
    -m '<subject>'
  ```

- Unless instructed otherwise, perform GitHub write actions (opening PRs,
  commenting, creating issues) as `littlenano` by scoping `GH_TOKEN` per
  command without switching the default `gh` account:

  ```bash
  GH_TOKEN="$(gh auth token --hostname github.com --user littlenano)" \
    gh pr create ...
  ```

  If `littlenano` is not authenticated in `gh` on this machine, stop and ask
  the user to log in rather than silently falling back to another account.

- Every temporary workaround must carry a `# TODO` stating the condition that
  allows removing it.
