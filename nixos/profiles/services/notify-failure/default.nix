{ config, lib, ... }:
let
  tgSend = config.programs.tg-send.wrapped;
in
{
  services.notify-failure = lib.mkIf config.programs.tg-send.enable {
    enable = true;
    config = {
      script = ''
        unit="$1"
        extra_information=""
        for e in "''${@:2}"; do
          extra_information+="$e"$'\n'
        done

        "${tgSend}" <<EOF
        $(systemctl status "$unit")

        $extra_information
        EOF
      '';
      environment = lib.mkIf config.networking.fw-proxy.enable config.networking.fw-proxy.environment;
    };
  };
}
