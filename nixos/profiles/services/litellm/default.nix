{
  config,
  lib,
  pkgs,
  ...
}:
let
  port = config.ports.litellm;
  postgresPort = config.ports.postgresql;
  dbPassword = config.sops.placeholder."litellm_db_password";

  # The container runs on podman's default bridge and the port forwarder connects
  # from that bridge, so it is the hop whose X-Forwarded-For the proxy may trust.
  # The subnet is pinned below rather than left to podman's built-in default, and
  # a missing value must fail loudly instead of falling back to a guess.
  podmanSubnet =
    let
      subnets = config.virtualisation.podman.defaultNetwork.settings.subnets or [ ];
    in
    if subnets == [ ] then
      throw "services/litellm: virtualisation.podman.defaultNetwork.settings.subnets must be set"
    else
      (lib.head subnets).subnet;

  terraformSecrets = {
    litellm_master_key = [ "podman-litellm.service" ];
    litellm_salt_key = [ "podman-litellm.service" ];
    litellm_db_password = [
      "litellm-db-password.service"
      "podman-litellm.service"
    ];
  };

  # None of these settings has an environment variable, so they need the mounted
  # config file: check_provider_endpoint makes a wildcard model expand into the
  # provider's real catalog in /v1/models, and disable_env_credential_login drops
  # the shared env/master-key UI login in favour of database users.
  configFile = (pkgs.formats.yaml { }).generate "litellm-config.yaml" {
    general_settings = {
      disable_env_credential_login = true;
      trusted_proxy_ranges = [ podmanSubnet ];
      # nginx already sends X-Forwarded-For; without this the recorded client IP
      # is the podman port forwarder's address for every request
      use_x_forwarded_for = true;
    };
    litellm_settings.check_provider_endpoint = true;
  };
in
{
  virtualisation.podman = {
    enable = true;
    defaultNetwork.settings.subnets = [
      {
        gateway = "10.88.0.1";
        subnet = "10.88.0.0/16";
      }
    ];
  };

  virtualisation.oci-containers.containers.litellm = {
    image = "ghcr.io/berriai/litellm:latest";
    labels."io.containers.autoupdate" = "registry";
    # the published port is forwarded to the container's bridge address, so the
    # container must not bind loopback; on the host only 127.0.0.1 is published
    cmd = [
      "--config"
      "/app/config.yaml"
      "--host"
      "0.0.0.0"
      "--port"
      (toString port)
    ];
    volumes = [
      "${configFile}:/app/config.yaml:ro"
      "/run/postgresql:/run/postgresql"
    ];
    environmentFiles = [ config.sops.templates."litellm-env".path ];
    # inside the bridge network the host is not localhost, so the container needs
    # the container-flavoured proxy variables (host.containers.internal)
    environment = lib.mkIf config.networking.fw-proxy.enable config.networking.fw-proxy.environmentContainer;
    ports = [ "127.0.0.1:${toString port}:${toString port}" ];
  };

  # image pulls run in these units on the host, so they take the host variables
  systemd.services."podman-litellm" = {
    environment = lib.mkIf config.networking.fw-proxy.enable config.networking.fw-proxy.environment;
    after = [ "litellm-db-password.service" ];
    requires = [ "litellm-db-password.service" ];
  };

  # the packaged timer pulls a new :latest and recreates the container daily
  systemd.timers.podman-auto-update.wantedBy = [ "timers.target" ];
  systemd.services.podman-auto-update.environment = lib.mkIf config.networking.fw-proxy.enable config.networking.fw-proxy.environment;

  services.postgresql = {
    enable = true;
    ensureDatabases = [ "litellm" ];
    ensureUsers = [
      {
        name = "litellm";
        ensureDBOwnership = true;
      }
    ];
    # the container reaches the database through the mounted socket, so it
    # cannot use peer authentication; this rule is inserted above the defaults
    authentication = "local litellm litellm scram-sha-256";
  };

  # ensureUsers creates the role without a password; the password is only ever
  # available at activation time, so it is applied here once.
  systemd.services.litellm-db-password = {
    wantedBy = [ "multi-user.target" ];
    after = [ "postgresql.target" ];
    requires = [ "postgresql.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      User = "postgres";
      EnvironmentFile = config.sops.templates."litellm-db-env".path;
      ExecStart = pkgs.writeShellScript "litellm-db-password" ''
        printf "ALTER ROLE litellm WITH PASSWORD '%s';\n" "$LITELLM_DB_PASSWORD" |
          ${config.services.postgresql.package}/bin/psql --no-psqlrc --set=ON_ERROR_STOP=1 --dbname=postgres
      '';
    };
  };

  services.nginx.virtualHosts."llm.*" = {
    forceSSL = true;
    inherit (config.security.acme.tfCerts."li7g_com".nginxSettings) sslCertificate sslCertificateKey;
    locations."/" = {
      proxyPass = "http://127.0.0.1:${toString port}";
      extraConfig = ''
        proxy_buffering off;
        proxy_cache off;
        proxy_read_timeout 1h;
      '';
    };
  };

  sops.templates."litellm-env".content = ''
    DATABASE_URL=postgresql://litellm:${dbPassword}@localhost:${toString postgresPort}/litellm?host=/run/postgresql
    LITELLM_MASTER_KEY=sk-${config.sops.placeholder."litellm_master_key"}
    LITELLM_SALT_KEY=sk-${config.sops.placeholder."litellm_salt_key"}
    STORE_MODEL_IN_DB=True
  '';
  sops.templates."litellm-db-env".content = ''
    LITELLM_DB_PASSWORD=${dbPassword}
  '';
  sops.secrets = lib.mapAttrs (_: restartUnits: {
    terraformOutput.enable = true;
    inherit restartUnits;
  }) terraformSecrets;
}
