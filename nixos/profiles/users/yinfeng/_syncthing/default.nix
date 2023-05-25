{
  config,
  lib,
  ...
}: let
  simpleDeviceNames = ["framework" "xps8930" "nuc"];
  simpleDevices = lib.listToAttrs (map
    (h:
      lib.nameValuePair h {
        id = config.lib.self.data.hosts.${h}.syncthing_device_id;
        addresses =
          [
            "dynamic"
          ]
          ++ lib.flatten (lib.lists.map
            (middle:
              lib.lists.map
              (protocol: "${protocol}://${h}.${middle}li7g.com:${toString config.ports.syncthing-transfer-yinfeng}")
              ["tcp" "tcp6" "udp" "udp6"])
            ["" "ts." "zt."]);
      })
    simpleDeviceNames);
  devices = lib.recursiveUpdate simpleDevices {
    k40 = {
      id = "IR2Q4MI-T53Q562-SMM2SW2-JXXCMCI-L2HOQUR-KLCRTUE-JCNFMPH-4RIBYQP";
    };
  };
  hostName = config.networking.hostName;
  others = lib.filterAttrs (h: _: h != hostName) devices;
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
        users.users.${user} = {
          inherit uid group;
          isNormalUser = true;
        };
        users.groups.${group} = {
          inherit gid;
        };
        services.syncthing = {
          enable = true;
          guiAddress = "127.0.0.1:${toString config.ports.syncthing-yinfeng}";
          openDefaultPorts = true;
          inherit user group;
          cert = "/run/secrets/syncthing_cert_pem";
          key = "/run/secrets/syncthing_key_pem";
          # new settings reverted
          # https://github.com/NixOS/nixpkgs/pull/233377
          # https://github.com/NixOS/nixpkgs/issues/232679
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
        system.stateVersion = config.system.stateVersion;
      };
    };
    sops.secrets."syncthing_cert_pem" = {
      sopsFile = config.sops-file.terraform;
      restartUnits = ["container@syncthing-yinfeng.service"];
    };
    sops.secrets."syncthing_key_pem" = {
      sopsFile = config.sops-file.terraform;
      restartUnits = ["container@syncthing-yinfeng.service"];
    };
    home-manager.users.yinfeng.home.global-persistence.directories = [
      "Syncthing"
    ];
    networking.firewall.allowedTCPPorts = with config.ports; [
      syncthing-transfer-yinfeng
      syncthing-discovery-yinfeng
    ];
  }
