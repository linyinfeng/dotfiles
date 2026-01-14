{
  config,
  pkgs,
  lib,
  ...
}:
let
  serviceMail = "${config.programs.service-mail.package}/bin/service-mail";
  tgSend = config.programs.tg-send.wrapped;
  mailAddress = "lin.yinfeng@outlook.com";
  smartdNotify = pkgs.writeShellScript "smartd-notify" ''
    set -e

    export PATH=${pkgs.coreutils}/bin:$PATH
    export PATH=${pkgs.inetutils}/bin:$PATH

    subject="$(hostname) - $SMARTD_FAILTYPE"

    echo "send mail"
    echo "$SMARTD_MESSAGE" | ${serviceMail} "smartd@li7g.com" "$SMARTD_ADDRESS" "$subject"

    echo "telegram push"
    ${tgSend} <<EOF
    $subject

    $SMARTD_MESSAGE
    EOF
  '';
in
{
  services.smartd = {
    enable = true;
    autodetect = true;
    # -a: monitor all attributes
    # -n standby,10: skip at most 10 checks if the device is sleep or standby
    # -s (S/../.././01|L/../../6/02):
    #   short self-test every day between 1-2am
    #   extended self-test weekly on Saturdays between 2-3am
    defaults.monitored = "-a -n standby,12 -s (S/../.././01|L/../../6/02) -m ${mailAddress} -M exec ${smartdNotify}";
  };
  systemd.services.smartd.environment = lib.mkIf config.networking.fw-proxy.enable config.networking.fw-proxy.environment;
  environment.systemPackages = with pkgs; [ smartmontools ];
}
