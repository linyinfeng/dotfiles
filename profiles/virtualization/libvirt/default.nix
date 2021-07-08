{ pkgs, ... }:

{
  virtualisation.libvirtd.enable = true;
  networking.firewall.checkReversePath = false;

  environment.systemPackages = with pkgs; [
    gnome.gnome-boxes
  ];

  environment.global-persistence = {
    directories = [
      "/var/lib/libvirt"
    ];
    user.directories = [
      ".config/libvirt"

      ".config/gnome-boxes"
      ".local/share/gnome-boxes"
    ];
  };
}
