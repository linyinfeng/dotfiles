{ pkgs, lib, ... }:

let
  udc = "a600000";
in
{
  mobile.usb.mode = lib.mkForce null; # manually configured
  environment.etc = {
    "gt/gt.conf".text = ''
      lookup-path=["/etc/gt/templates"]
    '';
    "gt/templates/g1.scheme".source = ./g1.scheme;
  };
  systemd.targets.gt = {
    description = "Hardware activated USB gadget";
    wants = [ "gt-enable@g1.service" ];
  };
  systemd.services."gt@" = {
    description = "Load USB Gadget Scheme";
    requires = [ "sys-kernel-config.mount" ];
    after = [ "sys-kernel-config.mount" ];
    path = with pkgs; [ gt ];
    script = ''
      gt load "$GADGET".scheme "$GADGET"
    '';
    preStop = ''
      gt rm --recursive --force "$GADGET"
    '';
    environment = {
      GADGET = "%i";
    };
    serviceConfig = {
      Type = "simple";
      RemainAfterExit = "yes";
    };
  };
  systemd.services."gt-enable@" = {
    description = "Enable USB Gadget";
    requires = [ "gt@%i.service" ];
    after = [ "gt@%i.service" ];
    path = with pkgs; [ gt ];
    script = ''
      gt enable "$GADGET" "${udc}"
    '';
    preStop = ''
      gt disable "$GADGET"
    '';
    environment = {
      GADGET = "%i";
    };
    serviceConfig = {
      Type = "simple";
      RemainAfterExit = "yes";
    };
  };
  services.udev.extraRules = ''
    SUBSYSTEM=="udc", ACTION=="add", TAG+="systemd", ENV{SYSTEMD_WANTS}+="gt.target"
  '';
}
