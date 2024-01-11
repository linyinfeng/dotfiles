{config, pkgs, ...}: {
  services.bind = {
    enable = true;
    zones = {}; # not authority
    cacheNetworks = ["any"];
    extraOptions = ''
      forwarders port 853 tls Cloudflare-DoT {
        1.1.1.1;
        1.0.0.1;
        2606:4700:4700::1111;
        2606:4700:4700::1001;
      };
    '';
    extraConfig = ''
      tls Cloudflare-DoT {
        ca-file "${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt";
        dhparam-file "${config.sops.secrets."dhparam_pem".path}";
        remote-hostname "one.one.one.one";
      };
    '';
  };
  sops.secrets."dhparam_pem" = {
    sopsFile = config.sops-file.get "terraform/infrastructure.yaml";
    restartUnits = ["bind.service"];
    owner = config.users.users.named.name;
    group = config.users.groups.named.name;
  };
}
