{
  config,
  lib,
  pkgs,
  ...
}:
let
  setup = pkgs.writeShellApplication {
    name = "influxdb-setup";
    runtimeInputs = with pkgs; [
      influxdb2
      curl
    ];
    text =
      let
        username = "yinfeng";
        org = "main-org";
        bucket = "main";
        retention = "30d";
        ensureBuckets = [
          "system"
          "minio"
          "minecraft"
          "http"
        ];
      in
      ''
        while [ "$(curl -sL -w "%{http_code}" "$INFLUX_HOST/ping")" != "204" ]; do
          # if influxdb is not up
          echo "wait for influxdb"
          sleep 1 # wait one second
        done

        if [ ! -f "$INFLUX_CONFIGS_PATH" ]; then
          echo "setting up..."

          password=$(cat "$CREDENTIALS_DIRECTORY/password")

          echo "y" | "$influx" setup \
            --username "${username}" \
            --password "$password" \
            --token "$(cat "$CREDENTIALS_DIRECTORY/token")" \
            --org "${org}" \
            --bucket "${bucket}" \
            --retention "${retention}"

          touch "$INFLUX_CONFIGS_PATH"
        fi

        # ensure buckets
        buckets=(${lib.concatMapStringsSep " " (s: "\"${s}\"") ensureBuckets})
        for bucket in "''${buckets[@]}"; do
          echo "ensure bucket '$bucket'"
          if "$influx" bucket list --org "$org" \
            --token "$(cat "$CREDENTIALS_DIRECTORY/token")" \
            --name "$bucket"; then
            echo "bucket '$bucket' already exists"
          else
            echo "create bucket '$bucket'"
            "$influx" bucket create \
              --token "$(cat "$CREDENTIALS_DIRECTORY/token")" \
              --name "$bucket" \
              --retention "$retention"
          fi
        done
      '';
  };
in
{
  services.influxdb2 = {
    enable = true;
    settings = {
      http-bind-address = ":${toString config.ports.influxdb}";
    };
  };
  system.build.influxdb2-setup-script = setup;
  systemd.services.influxdb2-setup = {
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${config.system.build.influxdb2-setup-script}";
      DynamicUser = true;
      LoadCredential = [
        "password:${config.sops.secrets."influxdb_password".path}"
        "token:${config.sops.secrets."influxdb_token".path}"
      ];
      StateDirectory = "influxdb2-setup";
    };
    environment = {
      INFLUX_HOST = "http://localhost:${toString config.ports.influxdb}";
      INFLUX_CONFIGS_PATH = "/var/lib/influxdb2-setup/configs";
    };
    after = [ "influxdb2.service" ];
    wantedBy = [ "multi-user.target" ];
  };
  # TODO restartUnits: can't change password and token currently
  sops.secrets."influxdb_password" = {
    terraformOutput.enable = true;
    restartUnits = [ "influxdb2-setup.service" ];
  };
  sops.secrets."influxdb_token" = {
    terraformOutput.enable = true;
    restartUnits = [ "influxdb2-setup.service" ];
  };
  environment.systemPackages = with pkgs; [ influxdb2 ];
  services.nginx.virtualHosts."influxdb.*" = {
    forceSSL = true;
    inherit (config.security.acme.tfCerts."li7g_com".nginxSettings) sslCertificate sslCertificateKey;
    locations."/" = {
      proxyPass = "http://127.0.0.1:${toString config.ports.influxdb}/";
    };
  };

  services.notify-failure.services = [ "influxdb2" ];
}
