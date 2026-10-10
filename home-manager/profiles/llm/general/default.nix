{
  config,
  lib,
  pkgs,
  ...
}:
let
  secretPaths = config.home.env.secretPaths;

  inherit (config.lib.file) mkOutOfStoreSymlink;

  # A second codex home whose provider is the local LiteLLM gateway. The release
  # tree under CODEX_HOME is self-contained and a few hundred megabytes, so this
  # home shares the one codex-install maintains and only keeps its own data.
  codex-li7g = pkgs.writeShellApplication {
    name = "codex-li7g";
    runtimeInputs = with pkgs; [ coreutils ];
    text = ''
      export CODEX_HOME="$HOME/.local/share/codex-li7g"

      key="${secretPaths.litellmApiKey}"
      if [ ! -r "$key" ]; then
        printf 'litellm api key is not readable: %s\n' "$key" >&2
        exit 1
      fi
      # Only the model request may see the gateway key; the agent's own shell
      # does not inherit it, see shell_environment_policy below.
      LITELLM_API_KEY="$(cat "$key")"
      export LITELLM_API_KEY

      # The provider is argv rather than config.toml: codex rewrites its own
      # config when its settings change, and a linked file cannot survive that.
      # codex-wrapper resolves the release inside the home set above.
      exec ${codex-wrapper}/bin/codex \
        -c 'model="aijws/gpt-6.1-sol"' \
        -c 'model_provider="li7g"' \
        -c 'model_reasoning_effort="medium"' \
        -c 'model_providers.li7g.name="llm.li7g.com"' \
        -c 'model_providers.li7g.base_url="https://llm.li7g.com/v1"' \
        -c 'model_providers.li7g.env_key="LITELLM_API_KEY"' \
        -c 'model_providers.li7g.wire_api="responses"' \
        -c 'shell_environment_policy.exclude=["LITELLM_API_KEY"]' \
        "$@"
    '';
  };

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
  home.packages = [
    codex-wrapper
    codex-install
  ]
  ++ lib.optionals (secretPaths ? litellmApiKey) [ codex-li7g ];

  home.file.".local/share/codex-li7g/packages/standalone" = lib.mkIf (secretPaths ? litellmApiKey) {
    source = mkOutOfStoreSymlink "${config.home.homeDirectory}/.codex/packages/standalone";
  };

  home.global-persistence.directories = [
    ".claude"
    ".codex"
    ".continue"
    ".codebuddy"
  ]
  ++ lib.optionals (secretPaths ? litellmApiKey) [ ".local/share/codex-li7g" ];

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
