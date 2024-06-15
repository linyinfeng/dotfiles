{ config, ... }:
{
  services.ace-bot = {
    enable = true;
    managerChatId = "148111617";
    tokenFile = config.sops.secrets."telegram-bot/ace-bot/token".path;
    extraModules = [
      (
        { pkgs, ... }:
        {
          nix.registry = {
            inherit (config.nix.registry) nixpkgs;
          };
          nix.nixPath = [ "nixpkgs=${pkgs.path}" ];
          environment.systemPackages = with pkgs; [
            util-linux
            procps
            curlFull
            wget
            texlive.combined.scheme-full
            python3Full
          ];
        }
      )
    ];
  };
  sops.secrets."telegram-bot/ace-bot/token" = {
    sopsFile = config.sops-file.host;
  };
  services.nginx.virtualHosts."ace-bot.*" = {
    forceSSL = true;
    inherit (config.security.acme.tfCerts."li7g_com".nginxSettings) sslCertificate sslCertificateKey;
    locations."/".root = "/var/lib/ace-bot/mount";
    extraConfig = ''
      index =404;
      autoindex on;
    '';
  };
  users.users.nginx.extraGroups = [ config.users.groups.ace-bot.name ];
}
