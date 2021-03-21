{ ... }:

{
  networking.networkmanager = {
    enable = true;
    enableStrongSwan = true;
  };

  environment.etc."ipsec.secrets".text = ''
    include ipsec.d/ipsec.nm-l2tp.secrets
  '';

  environment.global-persistence.directories = [
    "/etc/NetworkManager/system-connections"
  ];
}
