{ pkgs, lib, ... }:
{
  # canokey
  services.udev.packages = [ pkgs.nur.repos.linyinfeng.canokey-udev-rules ];

  services.pcscd = {
    enable = true;
    plugins = with pkgs; [ ccid ];
  };

  hardware.gpgSmartcards.enable = true;

  environment.systemPackages = with pkgs; [
    # TODO broken
    # yubikey-manager
    pcsctools
  ];

  # disabled
  security.pam.u2f = {
    enable = false;
    cue = false;
  };
  environment.global-persistence.user.directories = [ ".config/Yubico" ];

  # TODO wait for https://github.com/NixOS/nixpkgs/pull/308884
  systemd.user.services.gpg-agent.environment.LD_LIBRARY_PATH = "${lib.getLib pkgs.pcsclite}/lib";
  environment.sessionVariables.LD_LIBRARY_PATH = [ "${lib.getLib pkgs.pcsclite}/lib" ];
}
