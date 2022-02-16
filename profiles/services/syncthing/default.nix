{ config, pkgs, lib, ... }:

let
  cfg = config.services.syncthing;
  devices = {
    "t460p" = {
      id = "ESRNKCW-WFHWAZZ-H7YXVCM-YM43VOE-VIREZYF-EY7DKPO-UUZLHIH-RSHQBQR";
    };
    "xps8930" = {
      id = "6TJQETQ-R4ST2CI-3O3K3K7-GSA3XLZ-B7WB7QU-H4UCP2H-ZOMV6KN-G7EF5QS";
      addresses = [
        "tcp://nuc.li7g.com:22000"
      ];
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
    openDefaultPorts = true;
    user = "yinfeng";
    group = "users";
    cert = "${./certs/${hostName}.pem}";
    key = config.sops.secrets."syncthing/${hostName}".path;
    devices = others;
    folders = {
      "/var/lib/syncthing/Sync" = {
        id = "main";
        devices = otherNames;
        ignoreDelete = false;
        ignorePerms = false;
      };
      "/home/yinfeng/Data/Music" = {
        id = "music";
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
