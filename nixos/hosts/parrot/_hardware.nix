{
  config,
  pkgs,
  lib,
  ...
}:
lib.mkMerge [
  {
    # needed for desktop environments to detect/manage display brightness
    hardware.sensor.iio.enable = true;

    # needed for window manager to manage display brightness
    environment.systemPackages = with pkgs; [ wluma ];
    environment.etc."xdg/wluma/config.toml".text = ''
      [als.iio]
      path = "/sys/bus/iio/devices"
      thresholds = { 0 = "night", 20 = "dark", 80 = "dim", 250 = "normal", 500 = "bright", 800 = "outdoors" }

      [[output.backlight]]
      name = "eDP-1"
      path = "/sys/class/backlight/amdgpu_bl1"
      capturer = "wayland"
    '';
    environment.global-persistence.user.directories = [ ".local/share/wluma" ];
  }

  {
    boot.initrd.availableKernelModules = [
      "xhci_pci"
      "thunderbolt"
      "nvme"
      "usb_storage"
      "usbhid"
      "sd_mod"
    ];
    boot.extraModprobeConfig = ''
      options kvm-amd nested=1
    '';

    systemd.services = lib.mkIf config.services.displayManager.gdm.enable {
      gdm-prepare = {
        script = ''
          mkdir -p .config
          ln -sf ${./monitors.xml} .config/monitors.xml
        '';
        serviceConfig = {
          User = config.users.users.gdm.name;
          Group = config.users.users.gdm.name;
          StateDirectory = "gdm";
          WorkingDirectory = "/var/lib/gdm";
        };
        before = [ "display-manager.service" ];
        wantedBy = [ "display-manager.service" ];
      };
    };
    systemd.tmpfiles.settings."80-gdm-monitors" = {
      "${config.users.users.gdm.home}/.config/monitors.xml" = {
        "L+" = {
          argument = "${./monitors.xml}";
        };
      };
    };

    home-manager.users.yinfeng.services.kanshi.settings =
      let
        embedded = "eDP-1";
        labMonitor = "Lenovo Group Limited P27h-20 U5HCT52K";
        dormMonitor = "SKYDATA S.P.A. 24X1Q Unknown";
        portableMonitor = "ASEM S.p.A. ASM-125FC Unknown";
        captureCard = "A/Vaux Electronics AVT GC551G2 Unknown";
      in
      [
        {
          output = {
            criteria = embedded;
            scale = 2.0;
            adaptiveSync = true;
          };
        }
        {
          output = {
            criteria = labMonitor;
            scale = 1.0;
          };
        }
        {
          output = {
            criteria = dormMonitor;
            scale = 1.25;
          };
        }
        {
          output = {
            criteria = portableMonitor;
            scale = 1.25;
          };
        }
        {
          output = {
            criteria = captureCard;
            scale = 1440.0 / 1080.0;
            mode = "2560x1440@59.951Hz";
          };
        }
        {
          profile = {
            name = "undocked";
            outputs = [
              { criteria = embedded; }
            ];
          };
        }
        {
          profile = {
            name = "docked-lab";
            outputs = [
              {
                criteria = labMonitor;
                position = "0,0";
              }
              {
                criteria = embedded;
                position = "2560,580";
              }
            ];
          };
        }
        {
          profile = {
            name = "docked-lab-single";
            outputs = [
              {
                criteria = labMonitor;
                position = "0,0";
              }
            ];
          };
        }
        {
          profile = {
            name = "docked-dorm";
            outputs = [
              {
                criteria = embedded;
                position = "0,192";
              }
              {
                criteria = dormMonitor;
                position = "1536,0";
              }
            ];
          };
        }
        {
          profile = {
            name = "docked-capture-card";
            outputs = [
              {
                criteria = embedded;
                position = "0,192";
              }
              {
                criteria = captureCard;
                position = "1536,70";
              }
            ];
          };
        }
        {
          profile = {
            name = "with-portable-monitor";
            outputs = [
              {
                criteria = embedded;
                position = "0,0";
              }
              {
                criteria = portableMonitor;
                position = "1536,96";
              }
            ];
          };
        }
      ];
  }

  # powertop tweaks
  (
    let
      usbIds = {
        "Logitech, Inc. Unifying Receiver" = "046d:c52b";
        "Compx ATK Mouse 8K Dongle" = "373b:101b";
        "Holtek Semiconductor, Inc. USB Keyboard" = "1a81:2039";
      };
      parseUsbId =
        _name: id:
        let
          parsed = lib.splitString ":" id;
        in
        {
          vendor = lib.elemAt parsed 0;
          product = lib.elemAt parsed 1;
        };
      parsed = lib.mapAttrs parseUsbId usbIds;
    in
    {
      services.udev.extraRules = lib.concatMapAttrsStringSep "\n" (name: id: ''
        # Disable auto suspend for ${name}
        ACTION=="bind", SUBSYSTEM=="usb", ATTR{idVendor}=="${id.vendor}", ATTR{idProduct}=="${id.product}", TEST=="power/control", ATTR{power/control}="on"
      '') parsed;
      powerManagement.powertop = {
        enable = true;
        postStart = lib.concatMapAttrsStringSep "\n" (_name: id: ''
          ${lib.getExe' config.systemd.package "udevadm"} trigger -c bind -s usb -a idVendor=${id.vendor} -a idProduct=${id.product}
        '') parsed;
      };
    }
  )
]
