{ ... }:
{
  programs.gnupg = {
    agent = {
      enable = true;
      enableSSHSupport = true;
      enableExtraSocket = true;
    };
    dirmngr.enable = true;
  };
  environment.etc."dirmngr/dirmngr.conf".text = ''
    honor-http-proxy
  '';

  environment.global-persistence.user.directories = [
    {
      directory = ".gnupg";
      mode = "0700";
    }
  ];

  services.openssh.extraConfig = ''
    StreamLocalBindUnlink yes
  '';
}
