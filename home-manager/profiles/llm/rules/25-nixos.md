# NixOS Rules

- **NixOS, immutable** — the base PATH is minimal; everything
  installs via Nix, never into the system.
- **Never** use non-Nix package managers (`apt`/`yum`/`dnf`/`pacman`),
  `make install`, or `curl | sh`.
- **Never** root-scoped searches (`find /`, `grep -r /`, `fd /`, `rg /`)
  — `/nix/store` is huge and traversing `/` hangs. Scope to directories;
  for system files use `which`/`whereis`/`nix-locate`.
- Ephemeral tools: `nix shell nixpkgs#<pkg> -c <cmd>`, or
  `nix run nixpkgs#<pkg> -- <args>`; several at once:
  `nix shell nixpkgs#nodejs nixpkgs#jq -c bash`.
- Repo dev env: if `flake.nix`/`shell.nix` exists,
  `nix develop -c <cmd>` beats ad-hoc `nix shell` (pi runs
  non-interactive, so no bare `nix develop`).
- Python: `nix shell nixpkgs#python3 nixpkgs#python3Packages.<pkg>`,
  never pip.
- This machine's dotfiles live in `~/Projects/dotfiles`;
  declarative changes belong there.
