{ config, pkgs, ... }:
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
          environment.systemPackages = with pkgs; [ nix-index-with-db ];
        }
      )
    ];
  };
  systemd.slices.ace-bot = {
    sliceConfig = {
      CPUQuota = "100%";
    };
  };
  sops.secrets."telegram-bot/ace-bot/token" = {
    sopsFile = config.sops-file.host;
  };
  services.nginx.additionalModules = with pkgs.nginxModules; [ fancyindex ];
  services.nginx.virtualHosts."ace-bot.*" = {
    forceSSL = true;
    inherit (config.security.acme.tfCerts."li7g_com".nginxSettings) sslCertificate sslCertificateKey;
    locations."/".root = "/var/lib/ace-bot/mount/disk";
    extraConfig = ''
      index =404;
      fancyindex on;
      fancyindex_show_dotfiles on;
      fancyindex_exact_size off;
      fancyindex_localtime on;
      fancyindex_hide_parent_dir on;
    '';
  };
  users.users.nginx.extraGroups = [ config.users.groups.ace-bot.name ];
}
