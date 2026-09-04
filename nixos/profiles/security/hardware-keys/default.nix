{
  pkgs,
  ...
}:
{
  # canokey
  services.udev.packages = [ pkgs.linyinfeng.canokey-udev-rules ];

  services.pcscd = {
    enable = true;
    plugins = with pkgs; [ ccid ];
  };

  hardware.gpgSmartcards.enable = true;

  environment.systemPackages = with pkgs; [
    yubikey-manager
    pam_u2f
    pcsc-tools
  ];

  services.gnome.gcr-ssh-agent.enable = false;

  security.pam.u2f = {
    enable = true;
    settings.cue = true;
  };
  environment.global-persistence.user.directories = [ ".config/Yubico" ];
}
