{
  config,
  pkgs,
  lib,
  ...
}:
let
  blessingFile = pkgs.writeText "blessing.txt" ''
    祝你：新年快乐
    祝你：万事如意
    祝你：身体健康
    祝你：财源广进
    祝你：心想事成
    祝你：步步高升
    祝你：学业有成
    祝你：工作顺利
    祝你：蒸蒸日上
    祝你：梦想成真
    祝你：变成猫娘
  '';
in
{
  systemd.services.hongbao2026 = {
    script = ''
      "${lib.getExe pkgs.hongbao-rpn}" \
        --listen "[::1]:${toString config.ports.hongbao2026}" \
        --target 2026 \
        --blessing-file "${blessingFile}"
    '';
    serviceConfig = {
      Restart = "always";
      RestartSec = 5;
      DynamicUser = true;
      EnvironmentFile = [
        config.sops.templates."hongbao2026-env".path
      ];
    };
    restartTriggers = [ config.sops.templates."hongbao2026-env".content ];
    wantedBy = [ "multi-user.target" ];
  };

  services.nginx.virtualHosts."hongbao2026.*" = {
    forceSSL = true;
    inherit (config.security.acme.tfCerts."li7g_com".nginxSettings) sslCertificate sslCertificateKey;
    locations."/".proxyPass = "http://[::1]:${toString config.ports.hongbao2026}";
  };

  sops.templates."hongbao2026-env".content = ''
    JWT_SECRET=${config.sops.placeholder."hongbao2026_jwt_secret"}
    HONGBAO_CODE=${config.sops.placeholder."hongbao2026_hongbao_code"}
  '';
  sops.secrets."hongbao2026_jwt_secret" = {
    terraformOutput.enable = true;
    restartUnits = [ "hongbao2026.service" ];
  };
  sops.secrets."hongbao2026_hongbao_code" = {
    predefined.enable = true;
    restartUnits = [ "hongbao2026.service" ];
  };
}
