{ config, pkgs, lib, ... }:

let
  cfg = config.services.syncthing;
  devices = {
    "t460p" = {
      id = "ESRNKCW-WFHWAZZ-H7YXVCM-YM43VOE-VIREZYF-EY7DKPO-UUZLHIH-RSHQBQR";
    };
    "xps8930" = {
      id = "6TJQETQ-R4ST2CI-3O3K3K7-GSA3XLZ-B7WB7QU-H4UCP2H-ZOMV6KN-G7EF5QS";
    };
    "nuc" = {
      id = "FN5AKLS-VLUOTUK-RTKQWQ2-M3DOLFK-OMB7VJD-KA627GA-M2TY435-QFFLOQE";
    };
    "k40" = {
      id = "BSTUP5D-LGMGCRC-MKM2OZO-SB5RYDK-5N73YYS-YTWEFPK-WWWD3IK-YFUU2QU";
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
      "/var/lib/syncthing/Main" = {
        id = "main";
        devices = otherNames;
        ignoreDelete = false;
        ignorePerms = false;
      };
      "/var/lib/syncthing/Music" = {
        id = "main";
        devices = otherNames;
        ignoreDelete = false;
        ignorePerms = false;
      };
    };
  };
  sops.secrets."syncthing/${hostName}" = { };

  systemd.tmpfiles.rules = [
    "d ${cfg.dataDir} 0750 ${cfg.user} ${cfg.group}"
  ];

  environment.systemPackages = with pkgs; [
    syncthing
  ];
}
