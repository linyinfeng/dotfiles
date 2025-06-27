{ pkgs, ... }:
{
  # canokey
  services.udev.packages = [ pkgs.nur.repos.linyinfeng.canokey-udev-rules ];

  services.pcscd = {
    enable = true;
    plugins = with pkgs; [ ccid ];
  };

  hardware.gpgSmartcards.enable = true;

  environment.systemPackages = with pkgs; [
    yubikey-manager
    pcsctools
  ];

  services.gnome.gcr-ssh-agent.enable = false;

  # disabled
  security.pam.u2f = {
    enable = false;
    settings.cue = false;
  };
  environment.global-persistence.user.directories = [ ".config/Yubico" ];
}
