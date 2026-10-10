{
  lib,
  pkgs,
  ...
}:
let
  # Codex installs and updates itself into ~/.codex/packages/standalone, so nix
  # only owns the entry point. The wrapper follows the `current` symlink that
  # the standalone installer and codex's own updater maintain, rather than
  # ~/.local/bin, which persistence does not keep.
  codex-wrapper = pkgs.writeShellApplication {
    name = "codex";
    text = ''
      release="''${CODEX_HOME:-$HOME/.codex}/packages/standalone/current"
      for candidate in "$release/bin/codex" "$release/codex"; do
        if [ -x "$candidate" ]; then
          exec "$candidate" "$@"
        fi
      done
      printf 'codex is not installed; run codex-install\n' >&2
      exit 127
    '';
  };

  # Bootstrap or reinstall through the upstream installer, which codex's own
  # updater also invokes. CODEX_NON_INTERACTIVE skips its prompts, and putting
  # the bin dir on PATH keeps it from appending a PATH block to a shell profile.
  codex-install = pkgs.writeShellApplication {
    name = "codex-install";
    runtimeInputs = with pkgs; [
      bash
      coreutils
      curl
      gawk
      gnugrep
      gnused
      gnutar
      procps
    ];
    text = ''
      export CODEX_NON_INTERACTIVE=1
      export PATH="''${CODEX_INSTALL_DIR:-$HOME/.local/bin}:$PATH"

      installer=$(mktemp)
      trap 'rm -f "$installer"' EXIT
      if ! curl -fsSL https://chatgpt.com/codex/install.sh -o "$installer"; then
        curl -fsSL https://raw.githubusercontent.com/openai/codex/main/scripts/install/install.sh -o "$installer"
      fi
      sh "$installer"
    '';
  };
in
{
  imports = [
    ./_mcp.nix
  ];
  home.packages = with pkgs; [
    codex-wrapper
    codex-install
  ];

  home.global-persistence.directories = [
    ".claude"
    ".codex"
    ".continue"
    ".codebuddy"
  ];

  home.global-persistence.files = [ ".claude.json" ];

  systemd.user.services.codex-app-server = lib.mkIf pkgs.stdenv.hostPlatform.isLinux {
    Unit = {
      Description = "Codex app-server daemon";
      After = [ "default.target" ];
    };
    Service = {
      Type = "oneshot";
      ExecStart = "${codex-wrapper}/bin/codex app-server daemon start";
      RemainAfterExit = true;
    };
    Install.WantedBy = [ "default.target" ];
  };
}
