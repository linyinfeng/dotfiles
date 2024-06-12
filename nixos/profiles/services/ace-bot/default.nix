{ config, pkgs, ... }:
{
  services.ace-bot = {
    enable = true;
    managerChatId = "148111617";
    tokenFile = config.sops.secrets."telegram-bot/ace-bot/token".path;
  };
  nix.settings.allowed-users = [ "ace-bot" ];
  sops.secrets."telegram-bot/ace-bot/token" = {
    sopsFile = config.sops-file.host;
  };
  environment.systemPackages = with pkgs; [ texlive.combined.scheme-full ];
  services.nginx.virtualHosts."ace-bot.*" = {
    forceSSL = true;
    inherit (config.security.acme.tfCerts."li7g_com".nginxSettings) sslCertificate sslCertificateKey;
    locations."/".root = "/var/lib/ace-bot/home";
    extraConfig = ''
      autoindex on;
    '';
  };
  users.users.nginx.extraGroups = [ config.users.groups.ace-bot.name ];
}
