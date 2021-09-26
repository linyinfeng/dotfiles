{ config, pkgs, lib, ... }:

let
  telegram-send = config.programs.telegram-send.withConfig;
in
{
  services.notify-failure = lib.mkIf (config.programs.telegram-send.enable) {
    enable = true;
    config = {
      script = ''
        unit="$1"
        extra_information=""
        for e in "''${@:2}"; do
          extra_information+="$e"$'\n'
        done

        "${telegram-send}" --stdin <<EOF
        $(systemctl status "$unit")

        $extra_information
        EOF
      '';
      environment = lib.mkIf (config.networking.fw-proxy.enable) config.networking.fw-proxy.environment;
    };
  };
}
