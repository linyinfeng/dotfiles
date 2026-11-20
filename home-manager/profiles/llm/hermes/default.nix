{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.programs.hermes-team;
  hermesPackages = inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system};
  # Workers launch via sys.executable and need the package's Python environment.
  hermesAgent = hermesPackages.hermes-agent.withPythonPackages (_: [ ]);
  hermesHome = "${config.home.homeDirectory}/.hermes";
  roleFiles = {
    maintainer = ./_maintainer.md;
    ops = ./_ops.md;
    secretary = ./_secretary.md;
    team-maintainer = ./_team-maintainer.md;
  };
  codexUnits = lib.optional config.world.profiles.llm.general.enable "codex-app-server.service";
  webhookEnabled = cfg.webhook.tokenFile != null;
  dashboardEnabled = cfg.dashboard.port != null;
  telegramEnabled = cfg.telegram.envFile != null;
  persistentUnits = [
    "hermes-team.service"
  ]
  ++ codexUnits
  ++ lib.optional cfg.github.poll "hermes-github-notifications.timer"
  ++ lib.optional webhookEnabled "hermes-team-webhook.service"
  ++ lib.optional dashboardEnabled "hermes-team-dashboard.service";
  jobUnits = lib.optional cfg.github.poll "hermes-github-notifications.service";
  yaml = pkgs.formats.yaml { };
  telegramRoute = profile: {
    name = "team-${profile}";
    platform = "telegram";
    chat_id = toString cfg.telegram.userId;
    inherit profile;
  };
  telegramConfig = pkgs.linkFarm "hermes-team-telegram" {
    "config.yaml" = yaml.generate "hermes-team-telegram.yaml" {
      gateway = {
        multiplex_profiles = true;
        profile_routes =
          lib.mapAttrsToList (
            profile: id:
            (telegramRoute profile)
            // {
              name = "team-${profile}-topic";
              thread_id = toString id;
            }
          ) cfg.telegram.topicIds
          ++ [ (telegramRoute "secretary") ];
      };
    };
  };
  modelKey = config.home.env.secretPaths.litellmApiKey or null;
  seedConfig = yaml.generate "hermes-config.yaml" {
    model = {
      provider = "custom";
      default = "hermes";
      base_url = "https://llm.li7g.com/v1";
      api_key = "${"$"}{HERMES_TEAM_LITELLM_API_KEY}";
    };
    kanban.dispatch_in_gateway = true;
  };
  seeds = pkgs.writeText "hermes-team-seeds.json" (
    builtins.toJSON (
      {
        "config.yaml" = "${seedConfig}";
      }
      // lib.mergeAttrsList (
        lib.mapAttrsToList (role: soul: {
          "profiles/${role}/config.yaml" = "${seedConfig}";
          "profiles/${role}/SOUL.md" = "${soul}";
        }) roleFiles
      )
    )
  );

  team = pkgs.writeShellApplication {
    name = "hermes-team";
    runtimeInputs =
      with pkgs;
      [
        gh
        python3
      ]
      ++ lib.optionals pkgs.stdenv.hostPlatform.isLinux [ pkgs.systemd ];
    runtimeEnv = {
      HERMES_HOME = hermesHome;
      HERMES_TEAM_BIN = lib.getExe cfg.package;
      HERMES_TEAM_SEEDS = "${seeds}";
      HERMES_TEAM_GITHUB_USER = cfg.github.user;
      HERMES_TEAM_GITHUB_STATE_DIR = "${config.xdg.stateHome}/hermes-github-notifications";
      HERMES_TEAM_PERSISTENT_UNITS = lib.concatStringsSep " " persistentUnits;
      HERMES_TEAM_JOB_UNITS = lib.concatStringsSep " " jobUnits;
    }
    // lib.optionalAttrs (modelKey != null) { HERMES_TEAM_MODEL_KEY_FILE = modelKey; }
    // lib.optionalAttrs (cfg.github.tokenFile != null) {
      HERMES_TEAM_GITHUB_TOKEN_FILE = cfg.github.tokenFile;
    };
    text = ''exec python3 ${./.}/_team.py "$@"'';
  };
in
{
  options.programs.hermes-team = {
    package = lib.mkPackageOption { hermes-agent = hermesAgent; } "hermes-agent" { };
    github = {
      user = lib.mkOption {
        type = lib.types.str;
        default = "littlenano";
        description = "GitHub login whose notifications the maintainer polls.";
      };
      tokenFile = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        description = "Runtime path to the GitHub token. If unset, use the saved gh token for github.user.";
      };
      poll = lib.mkEnableOption "polling unread GitHub notifications every ten minutes";
    };
    webhook = {
      tokenFile = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        description = "Runtime path to the Grafana bearer token. Setting it enables the loopback receiver.";
      };
      port = lib.mkOption {
        type = lib.types.port;
        description = "Local port for the Grafana Webhook receiver.";
      };
    };
    dashboard.port = lib.mkOption {
      type = lib.types.nullOr lib.types.port;
      default = null;
      description = "Loopback port for the Hermes dashboard. Set only behind an authenticated reverse proxy.";
    };
    telegram = {
      envFile = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        description = "Runtime environment file containing TELEGRAM_BOT_TOKEN.";
      };
      userId = lib.mkOption {
        type = lib.types.ints.positive;
        description = "Telegram account allowed to use the team bot.";
      };
      topicIds = lib.mkOption {
        type = lib.types.addCheck (lib.types.attrsOf lib.types.ints.positive) (
          topics:
          let
            ids = lib.attrValues topics;
          in
          lib.all (role: builtins.hasAttr role roleFiles) (lib.attrNames topics)
          && lib.all (id: id > 1) ids
          && lib.length (lib.unique ids) == lib.length ids
        );
        default = { };
        description = "Private Telegram topic IDs keyed by Hermes team profile (requires BotFather Threaded Mode).";
      };
    };
  };

  config = {
    home.packages = [
      cfg.package
      team
    ];
    home.global-persistence.directories = [ ".hermes" ];

    systemd.user = lib.mkIf pkgs.stdenv.hostPlatform.isLinux {
      targets.hermes-team = {
        Unit = {
          Description = "Hermes team services";
          Wants = persistentUnits ++ [ "hermes-team-monitor.timer" ];
        };
        Install.WantedBy = [ "default.target" ];
      };
      services = {
        codex-app-server = lib.mkIf (codexUnits != [ ]) {
          Unit = {
            # The target starts Codex before the gateway. Ordering Codex after
            # default.target would create a cycle at login.
            After = lib.mkForce [ ];
            PartOf = [ "hermes-team.target" ];
            OnFailure = [ "hermes-team-monitor.service" ];
          };
          Install.WantedBy = lib.mkForce [ ];
        };
        hermes-team = {
          Unit = {
            Description = "Hermes gateway and Kanban dispatcher";
            Wants = codexUnits;
            After = codexUnits;
            PartOf = [ "hermes-team.target" ];
            OnFailure = [ "hermes-team-monitor.service" ];
          };
          Service = {
            ExecStartPre = [ "${lib.getExe team} prepare" ];
            ExecStart = "${lib.getExe cfg.package} -p default gateway run";
            EnvironmentFile = lib.mkIf telegramEnabled cfg.telegram.envFile;
            # SIGTERM during activation or systemctl stop makes the gateway exit 1, marking the unit
            # failed and firing OnFailure=hermes-team-monitor.service before activation restarts it.
            # ExecStop sends the gateway's planned-stop SIGINT only to the main PID, which exits 0
            # without firing OnFailure. Systemd's default SIGTERM still reaches the rest of the cgroup.
            ExecStop = "-${pkgs.procps}/bin/kill -INT $MAINPID";
            Restart = "on-failure";
            RestartSec = "10s";
            Environment = [
              "HERMES_HOME=${hermesHome}"
              "HERMES_BIN=${lib.getExe cfg.package}"
              "PATH=${
                lib.makeBinPath [
                  team
                  pkgs.git
                  pkgs.gh
                ]
              }:${config.home.profileDirectory}/bin:/run/current-system/sw/bin"
            ]
            ++ lib.optionals config.home.env.proxy.enable config.home.env.proxy.stringEnvironment
            ++ lib.optionals telegramEnabled [
              "TELEGRAM_ALLOWED_USERS=${toString cfg.telegram.userId}"
              "HERMES_MANAGED_DIR=${telegramConfig}"
            ];
            UMask = "0077";
          };
        };
        hermes-github-notifications = lib.mkIf cfg.github.poll {
          Unit = {
            Description = "Queue unread GitHub notifications for Hermes";
            PartOf = [ "hermes-team.target" ];
            OnFailure = [ "hermes-team-monitor.service" ];
          };
          Service = {
            Type = "oneshot";
            ExecStart = "${lib.getExe team} github";
            Environment = lib.mkIf config.home.env.proxy.enable config.home.env.proxy.stringEnvironment;
            StateDirectory = "hermes-github-notifications";
            UMask = "0077";
          };
        };
        hermes-team-monitor = {
          Unit = {
            Description = "Route Hermes team service failures to its maintainer";
            Requisite = [ "hermes-team.target" ];
            After = [ "hermes-team.target" ];
            PartOf = [ "hermes-team.target" ];
          };
          Service = {
            Type = "oneshot";
            ExecStart = "${lib.getExe team} monitor";
            StateDirectory = "hermes-team-monitor";
            UMask = "0077";
          };
        };
        hermes-team-webhook = lib.mkIf webhookEnabled {
          Unit = {
            Description = "Receive Grafana alerts for the Hermes team";
            PartOf = [ "hermes-team.target" ];
            OnFailure = [ "hermes-team-monitor.service" ];
          };
          Service = {
            ExecStart = "${lib.getExe team} webhook ${toString cfg.webhook.port}";
            LoadCredential = "grafana-token:${cfg.webhook.tokenFile}";
            Restart = "on-failure";
            RestartSec = "10s";
            UMask = "0077";
          };
        };
        hermes-team-dashboard = lib.mkIf dashboardEnabled {
          Unit = {
            Description = "Hermes web dashboard and Kanban";
            After = [ "hermes-team.service" ];
            PartOf = [ "hermes-team.target" ];
            OnFailure = [ "hermes-team-monitor.service" ];
          };
          Service = {
            ExecStart = "${lib.getExe cfg.package} -p default dashboard --host 127.0.0.1 --port ${toString cfg.dashboard.port} --no-open --skip-build";
            Environment = [ "HERMES_HOME=${hermesHome}" ];
            Restart = "on-failure";
            RestartSec = "10s";
            UMask = "0077";
          };
        };
      };
      timers = {
        hermes-github-notifications = lib.mkIf cfg.github.poll {
          Unit = {
            Description = "Poll GitHub notifications every ten minutes";
            PartOf = [ "hermes-team.target" ];
            OnFailure = [ "hermes-team-monitor.service" ];
          };
          Timer.OnCalendar = "*:0/10";
        };
        hermes-team-monitor = {
          Unit = {
            Description = "Check Hermes team service state every minute";
            PartOf = [ "hermes-team.target" ];
          };
          Timer.OnCalendar = "*:*:00";
        };
      };
    };
  };
}
