{ ... }:

{
  programs.gnupg = {
    agent.enable = true;
    agent.enableSSHSupport = true;
    dirmngr.enable = true;
  };
  environment.etc."dirmngr/dirmngr.conf".text = ''
    honor-http-proxy
  '';
}
