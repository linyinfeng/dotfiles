{ ... }:
{
  world = {
    profiles = {
      audio.midi.enable = true;
      boot = {
        binfmt.enable = true;
        plymouth.enable = true;
      };
      hardware = {
        rtl-sdr.enable = true;
        tablet.enable = true;
      };
      networking = {
        mobile-nixos-usb.enable = true;
        network-manager.enable = true;
        tools.enable = true;
      };
      nix = {
        auto-gen.enable = true;
        hydra-builder-client.enable = true;
        hydra-builder-server.enable = true;
        nixbuild.enable = true;
      };
      programs = {
        localsend.enable = true;
        service-mail.enable = true;
        solaar.enable = true;
        terminal-multiplexing.enable = true;
        tg-send.enable = true;
        tools.enable = true;
      };
      security.hardware-keys.enable = true;
      services = {
        auto-upgrade.enable = true;
        bluetooth.enable = true;
        flatpak.enable = true;
        homed.enable = true;
        iperf3.enable = true;
        kde-connect.enable = true;
        portal-client.enable = true;
        printing.enable = true;
        smartd.enable = true;
        snapper.enable = true;
        system76-scheduler.enable = true;
      };
      system.types.workstation.enable = true;
    };
    suites = {
      backup.enable = true;
      base.enable = true;
      monitoring.enable = true;
      multimediaDev.enable = true;
      network.enable = true;
      virtualization.enable = true;
    };
  };
}
