{ pkgs, ... }:

let
  disabledGnomeKeyringSsh = pkgs.runCommand "gnome-keyring-ssh.desktop" { } ''
    cp "${pkgs.gnome.gnome-keyring}/etc/xdg/autostart/gnome-keyring-ssh.desktop" tmp.desktop
    chmod 644 tmp.desktop
    echo "Hidden=true" >> tmp.desktop
    cp tmp.desktop $out
  '';
in
{
  programs.gpg = {
    enable = true;
    settings = {
      keyserver = "hkps://keys.openpgp.org";
    };
    scdaemonSettings = {
      # canokey support
      card-timeout = "5";
      disable-ccid = true;
    };
  };
  home.packages = with pkgs; [
    haskellPackages.hopenpgp-tools
  ];

  # disable GNOME Keyring SSH agent
  xdg.configFile."autostart/gnome-keyring-ssh.desktop".source = disabledGnomeKeyringSsh;
}
