{
  pkgs,
  config,
  lib,
  osConfig,
  ...
}:
let
  context = pkgs.runCommand "pi-agents-md" { } ''
    cat ${../_context}/*.md > $out
  '';

  inherit (config.lib.file) mkOutOfStoreSymlink;

  commandNotFoundModel = "deepseek/deepseek-flash";

  # pi rewrites settings.json at runtime (model selection, extension settings),
  # so this file stays writable and the switch merges into it instead of
  # replacing it wholesale.
  piSettingsFile = "${config.home.homeDirectory}/.pi/agent/settings.json";

  pi-sandbox = pkgs.writeShellApplication {
    name = "pi-sandbox";
    runtimeInputs = [ pkgs.llm-agents.nono ];
    text = ''
      nono pull nolabs-ai/pi
      nono update
      exec nono run --profile pi --allow-cwd -- pi "$@"
    '';
  };

  command-not-found-adaptor = pkgs.writers.writePython3Bin "command-not-found-adaptor" { } (
    builtins.readFile ./command-not-found-adaptor.py
  );

  command-not-found-agent = pkgs.writeShellApplication {
    name = "command-not-found-agent";
    bashOptions = [
      "errexit"
      "nounset"
    ];
    runtimeInputs = [
      config.programs.pi-coding-agent.package
      command-not-found-adaptor
      pkgs.bash
      pkgs.jq
      pkgs.mdcat
    ]
    ++ config.programs.pi-coding-agent.extraPackages;
    text = ''
      session_id="''${COMMAND_NOT_FOUND_SESSION_ID:-}"
      session_id="''${session_id//[^[:alnum:]-]/_}"
      [ -n "$session_id" ] || session_id=$(cat /proc/sys/kernel/random/uuid)
      export COMMAND_NOT_FOUND_SESSION_ID="$session_id"

      session_dir="$HOME/.pi/command-not-found/sessions/$session_id"
      mkdir -p "$session_dir"
      chmod 700 "$session_dir"

      prompt=$(jq -cn \
        --arg session_id "$session_id" \
        --arg cwd "$PWD" \
        --arg input "$(printf '%q ' "$@")" \
        '{session_id: $session_id, cwd: $cwd, input: $input}')
      exec pi \
        --model "${commandNotFoundModel}" \
        --mode json \
        --no-context-files \
        --session "$session_dir/session.jsonl" \
        --append-system-prompt "${./command-not-found-system-prompt.md}" \
        -- "$prompt" \
        | exec command-not-found-adaptor
    '';
  };
in
{
  programs.pi-coding-agent = {
    enable = true;
    package = pkgs.llm-agents.pi.override {
      useBun = false;
    };
    inherit context;

    extraPackages = with pkgs; [
      agent-browser
      ast-grep
      bun
      nodejs
      rtk
    ];

    settings = {
      theme = "light/dark";
      collapseChangelog = true;
      enableInstallTelemetry = false;
      outputPad = 0;
      hideThinkingBlock = true;
      terminal.showTerminalProgress = true;
      defaultProvider = "opencode-go";
      defaultModel = "deepseek-flash";
      enabledModels = [
        # keep-sorted start
        "cc-switch/gpt-6-astra"
        "deepseek/deepseek-flash"
        "opencode-go/deepseek-flash"
        "opencode-go/glm-5.3-flash"
        "opencode-go/hy4-preview"
        "openrouter/google/gemini-3.8-flash"
        "zai-coding-cn/glm-5.3-flash"
        # keep-sorted end
      ];
      defaultThinkingLevel = "high";
      steeringMode = "all";
      tokenSpeed = {
        display = "ttft";
        useProviderTokens = true;
        tpsBlazing = 200;
        tpsFast = 100;
        tpsMedium = 60;
        tpsSlow = 30;
      };
      packages = [
        # keep-sorted start
        "npm:@juicesharp/rpiv-todo"
        "npm:@mrclrchtr/supi-context"
        "npm:@narumitw/pi-usage"
        "npm:pi-agent-browser-native"
        "npm:pi-background-tasks"
        "npm:pi-btw"
        "npm:pi-goal-x"
        "npm:pi-lens"
        "npm:pi-mcp-adapter"
        "npm:pi-simplify"
        "npm:pi-subagents"
        "npm:pi-token-speed"
        "npm:pi-web-access"
        {
          source = "${config.xdg.configHome}/nono/packages/nolabs-ai/pi";
        }
        # keep-sorted end
      ];
    };
  };

  home.file.${piSettingsFile}.enable = false;

  home.activation.piSettingsMerge = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
    settings=${piSettingsFile}
    generated=${config.home.file.${piSettingsFile}.source}
    if [ -f "$settings" ] && ${pkgs.jq}/bin/jq -s '.[0] * .[1]' "$settings" "$generated" > "$settings.merged"; then
      run mv -f "$settings.merged" "$settings"
    else
      rm -f "$settings.merged"
      warnEcho "$settings is not valid JSON; replacing it with the declared settings"
      run cp -f "$generated" "$settings"
    fi
  '';

  home.file.".config/pi/web-search.json".source =
    mkOutOfStoreSymlink
      osConfig.sops.templates."pi-web-search-config".path;

  home.file.".config/nono/profiles/pi.json".source = ./nono-pi-profile.json;

  home.file.".pi/agent/auth.json".source = mkOutOfStoreSymlink osConfig.sops.templates."pi-auth".path;

  home.file.".pi/agent/models.json".text = builtins.toJSON {
    providers = {
      "cc-switch" = {
        name = "cc-switch";
        baseUrl = "http://127.0.0.1:15721/v1";
        apiKey = "sk-local";
        api = "openai-completions";
        models = [
          {
            id = "gpt-6-astra";
            name = "GPT-6 Astra";
            api = "openai-responses";
            reasoning = true;
            thinkingLevelMap = {
              off = null;
              minimal = null;
              low = "low";
              medium = "medium";
              high = "high";
              xhigh = "xhigh";
              max = "max";
            };
            input = [
              "text"
              "image"
            ];
            contextWindow = 272000;
            maxTokens = 128000;
            cost = {
              input = 10;
              output = 50;
              cacheRead = 1;
              cacheWrite = 12.5;
              tiers = [
                {
                  inputTokensAbove = 272000;
                  input = 20;
                  output = 75;
                  cacheRead = 2;
                  cacheWrite = 25;
                }
              ];
            };
          }
        ];
      };
      # models.dev has not picked up the DeepSeek V4.1 Flash rename yet
      # (its deepseek provider data is from 2026-08-25), so declare it here.
      deepseek = {
        models = [
          {
            id = "deepseek-flash";
            name = "DeepSeek V4.1 Flash";
            api = "openai-completions";
            baseUrl = "https://api.deepseek.com";
            reasoning = true;
            input = [
              "text"
            ];
            cost = {
              input = 0.15;
              output = 0.6;
              cacheRead = 0.003;
              cacheWrite = 0;
            };
            contextWindow = 1000000;
            maxTokens = 384000;
            compat = {
              supportsStore = false;
              supportsDeveloperRole = false;
              maxTokensField = "max_tokens";
              requiresReasoningContentOnAssistantMessages = true;
              thinkingFormat = "deepseek";
            };
            thinkingLevelMap = {
              minimal = null;
              low = "low";
              medium = null;
              high = "high";
              max = "max";
            };
          }
        ];
      };
      openrouter = {
        modelOverrides = {
          "google/gemini-3.8-flash" = {
            compat = {
              openRouterRouting = {
                order = [ "google-vertex/global" ];
                allow_fallbacks = false;
              };
            };
          };
        };
      };
    };
  };

  home.packages = [
    command-not-found-agent
    pi-sandbox
  ];

  passthru.command-not-found-agent = command-not-found-agent;

  programs.fish.interactiveShellInit = ''
    set -gx COMMAND_NOT_FOUND_AGENT command-not-found-agent
  '';

  # pi-lens: prefer PATH tools only, no self-install of npm binaries
  home.sessionVariables = {
    PI_LENS_DISABLE_TOOL_INSTALL = "1";
    PI_LENS_DISABLE_LSP_INSTALL = "1";
  };

  home.global-persistence.directories = [
    ".pi"
    ".pi-lens"
  ];

  programs.git.ignores = [
    "/.pi"
    "/.pi-glla"
    "/.pi-subagents"
  ];
}
