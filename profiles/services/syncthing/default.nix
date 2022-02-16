{ config, pkgs, lib, ... }:

let
  devices = {
    "t460p" = {
      id = "";
      # addresses = [
      #   "t460p.ts.li7g.com"
      # ];
    };
    "xps8930" = {
      id = "6TJQETQ-R4ST2CI-3O3K3K7-GSA3XLZ-B7WB7QU-H4UCP2H-ZOMV6KN-G7EF5QS";
      # addresses = [
      #   "xps8930.ts.li7g.com"
      # ];
    };
    "nuc" = {
      id = "FN5AKLS-VLUOTUK-RTKQWQ2-M3DOLFK-OMB7VJD-KA627GA-M2TY435-QFFLOQE";
      # addresses = [
      #   "nuc.ts.li7g.com"
      # ];
    };
  };
  hostName = config.networking.hostName;
  me = devices.${hostName};
  others = lib.filterAttrs (h: _: h != hostName) devices;
  deviceNames = lib.attrNames devices;
  otherNames = lib.attrNames others;
in
{
  services.syncthing = {
    enable = true;
    cert = "${./certs/${hostName}.pem}";
    key = config.sops.secrets."syncthing/${hostName}".path;
    devices = others;
    folders = {
      "/var/lib/syncthing/main" = {
        id = "main";
        devices = otherNames;
        ignoreDelete = false;
        ignorePerms = false;
      };
    };
  };
  sops.secrets."syncthing/${hostName}" = { };

  environment.systemPackages = with pkgs; [
    syncthing
  ];
}
