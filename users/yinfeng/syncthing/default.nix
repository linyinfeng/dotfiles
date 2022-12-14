{ self, config, lib, ... }:

let
  simpleDeviceNames = [ "framework" "xps8930" "nuc" ];
  simpleDevices = lib.listToAttrs (map
    (h: lib.nameValuePair h {
      id = self.lib.data.hosts.${h}.syncthing_device_id;
    })
    simpleDeviceNames);
  devices = lib.recursiveUpdate simpleDevices {
    nuc.addresses = [
      "tcp://nuc.li7g.com:22000"
    ];
    k40 = {
      id = "IR2Q4MI-T53Q562-SMM2SW2-JXXCMCI-L2HOQUR-KLCRTUE-JCNFMPH-4RIBYQP";
    };
  };
  hostName = config.networking.hostName;
  me = devices.${hostName};
  others = lib.filterAttrs (h: _: h != hostName) devices;
  deviceNames = lib.attrNames devices;
  otherNames = lib.attrNames others;

  user = "yinfeng";
  group = config.users.users.yinfeng.group;
  uid = config.users.users.${user}.uid;
  gid = config.users.groups.${group}.gid;
in

lib.mkIf (devices ? ${hostName}) {
  containers.syncthing-yinfeng = {
    autoStart = true;
    ephemeral = true;
    privateNetwork = false;
    bindMounts = {
      "/var/lib/syncthing" = {
        hostPath = "/home/yinfeng/Syncthing";
        isReadOnly = false;
      };
      "/run/secrets/syncthing_cert_pem" = {
        hostPath = config.sops.secrets."syncthing_cert_pem".path;
        isReadOnly = true;
      };
      "/run/secrets/syncthing_key_pem" = {
        hostPath = config.sops.secrets."syncthing_key_pem".path;
        isReadOnly = true;
      };
    };
    config = {
      system.stateVersion = config.system.stateVersion;
      users.users.${user} = {
        inherit uid group;
        isNormalUser = true;
      };
      users.groups.${group} = {
        inherit gid;
      };
      services.syncthing = {
        enable = true;
        openDefaultPorts = true;
        inherit user group;
        cert = "/run/secrets/syncthing_cert_pem";
        key = "/run/secrets/syncthing_key_pem";
        devices = others;
        folders = {
          "main" = {
            path = "/var/lib/syncthing/Main";
            devices = otherNames;
            ignoreDelete = false;
            ignorePerms = false;
          };
          "music" = {
            path = "/var/lib/syncthing/Music";
            devices = otherNames;
            ignoreDelete = false;
            ignorePerms = false;
          };
        };
      };
    };
  };
  sops.secrets."syncthing_cert_pem" = {
    sopsFile = config.sops.getSopsFile "terraform/hosts/${hostName}.yaml";
    restartUnits = [ "container@syncthing-yinfeng.service" ];
  };
  sops.secrets."syncthing_key_pem" = {
    sopsFile = config.sops.getSopsFile "terraform/hosts/${hostName}.yaml";
    restartUnits = [ "container@syncthing-yinfeng.service" ];
  };
  home-manager.users.yinfeng.home.global-persistence.directories = [
    "Syncthing"
  ];
}
