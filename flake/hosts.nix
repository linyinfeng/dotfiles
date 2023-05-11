{
  config,
  self,
  inputs,
  lib,
  getSystem,
  ...
}: let
  inherit (inputs.nixpkgs.lib) nixosSystem;
  buildSuites = profiles: f: lib.mapAttrs (_: lib.flatten) (lib.fix (f profiles));

  nixosModules = self.lib.buildModuleList ../nixos/modules;
  nixosProfiles = self.lib.rakeLeaves ../nixos/profiles;
  nixosSuites = buildSuites nixosProfiles (profiles: suites: {
    nixSettings = with profiles.nix; [gc settings cachix];
    base =
      suites.nixSettings
      ++ (with profiles; [
        programs.tools
        programs.nix-index
        services.openssh
        services.dbus
        services.oom-killer
        security.polkit
        global-persistence
        system.common
        system.sysrq
        users.root
      ]);

    network = with profiles; [
      networking.avahi
      networking.resolved
      networking.tailscale
      networking.zerotier
      networking.tools
      networking.dn42
      security.fail2ban
      security.firewall
    ];
    backup = with profiles; [
      services.restic
    ];
    multimedia = with profiles; [
      graphical.gnome
      graphical.kde
      graphical.hyprland
      graphical.sway
      graphical.fonts
      graphical.i18n
      services.pipewire
    ];
    development = with profiles; [
      development.shells
      development.documentation
      programs.adb
      services.gnupg
    ];
    multimediaDev =
      suites.multimedia
      ++ suites.development
      ++ (with profiles; [development.ides]);
    virtualization = with profiles; [
      virtualization.libvirt
      virtualization.wine
      virtualization.podman
    ];
    games = with profiles.graphical.game; [steam];
    monitoring = with profiles; [
      services.telegraf
      services.telegraf-system
      services.promtail
    ];

    workstation =
      (
        with suites;
          base
          ++ multimediaDev
          ++ virtualization
          ++ network
          ++ backup
          ++ monitoring
      )
      ++ (with profiles; [
        system.types.workstation
        networking.network-manager
        services.bluetooth
        services.auto-upgrade
        services.kde-connect
        services.printing
        security.hardware-keys
        hardware.rtl-sdr
        nix.nix-ld
      ]);
    mobileWorkstation = suites.workstation;

    server =
      (
        with suites;
          base
          ++ network
          ++ backup
          ++ monitoring
      )
      ++ (with profiles; [
        system.types.server
        services.auto-upgrade
        networking.bbr
      ]);
    homeServer =
      suites.server
      ++ (with profiles; [
        networking.network-manager
      ]);
  });

  hmModules = self.lib.buildModuleList ../home-manager/modules;
  hmProfiles = self.lib.rakeLeaves ../home-manager/profiles;
  hmSuites = buildSuites hmProfiles (profiles: suites: {
    base = with profiles; [git];
    multimedia = with profiles; [
      gnome
      hyprland
      sway
      desktop-applications
      chromium
      firefox
      rime
      fcitx5
      fonts
      mime
      obs-studio
      minecraft
    ];
    development = with profiles; [
      development
      direnv
      emacs
      pssh
      tools.nix
      tools.network
      tools.other
      tex
      postmarketos
      awscli
      terraform
      shells
      kitty
    ];
    virtualization = [];
    multimediaDev =
      suites.multimedia
      ++ suites.development
      ++ (with profiles; [xdg-dirs vscode]);
    synchronize = with profiles; [onedrive digital-paper];
    security = with profiles; [gpg];
    other = with profiles; [hledger];

    full = with suites;
      base
      ++ multimediaDev
      ++ virtualization
      ++ synchronize
      ++ security
      ++ other;
  });

  commonNixosModules =
    nixosModules
    ++ [
      inputs.home-manager.nixosModules.home-manager
      inputs.sops-nix.nixosModules.sops
      inputs.impermanence.nixosModules.impermanence
      inputs.disko.nixosModules.disko
      inputs.flake-utils-plus.nixosModules.autoGenFromInputs
      inputs.lanzaboote.nixosModules.lanzaboote
      inputs.linyinfeng.nixosModules.vlmcsd
      inputs.linyinfeng.nixosModules.tprofile
      inputs.linyinfeng.nixosModules.tg-send
      inputs.linyinfeng.nixosModules.commit-notifier
      inputs.linyinfeng.nixosModules.dot-tar
      inputs.linyinfeng.nixosModules.matrix-media-repo
      inputs.attic.nixosModules.atticd
      inputs.oranc.nixosModules.oranc
      inputs.ace-bot.nixosModules.ace-bot
      inputs.hyprland.nixosModules.default

      {
        lib.self = self.lib;
        home-manager = {
          sharedModules = commonHmModules;
          extraSpecialArgs = hmSpecialArgs;
        };
        system.configurationRevision =
          if self ? rev
          then self.rev
          else null;
      }
    ];

  commonHmModules =
    hmModules
    ++ [
      inputs.hyprland.homeManagerModules.default

      {
        lib.self = self.lib;
      }
    ];

  nixosSpecialArgs = {
    inherit inputs self;
    profiles = nixosProfiles;
    suites = nixosSuites;
  };

  hmSpecialArgs = {
    inherit inputs self;
    profiles = hmProfiles;
    suites = hmSuites;
  };

  mkHost = {
    name,
    configurationName ? name,
    system,
    extraModules ? [],
  }: {
    ${name} = nixosSystem {
      inherit system;
      inherit ((getSystem system).allModuleArgs) pkgs;
      specialArgs = nixosSpecialArgs;
      modules =
        commonNixosModules
        ++ extraModules
        ++ lib.optional (configurationName != null) ../nixos/hosts/${configurationName}
        ++ [
          ({lib, ...}: {
            networking.hostName = lib.mkDefault name;
          })
        ];
    };
  };

  mkHostAllSystems = {
    name,
    extraModules ? [],
  }:
    lib.mkMerge (
      lib.lists.map
      (system:
        mkHost {
          name = "${name}-${system}";
          configurationName = name;
          inherit system extraModules;
        })
      config.systems
    );
in {
  passthru = {
    inherit nixosProfiles nixosModules nixosSuites hmProfiles hmModules hmSuites;
  };

  flake.nixosConfigurations = lib.mkMerge [
    (mkHost {
      name = "framework";
      system = "x86_64-linux";
      extraModules = with inputs.nixos-hardware.nixosModules; [
        common-pc
        common-cpu-intel
        common-pc-ssd
        # disabled infavor of hosts/framework/hardware.nix
        # framework-12th-gen-intel
      ];
    })

    (mkHost {
      name = "xps8930";
      system = "x86_64-linux";
      extraModules = with inputs.nixos-hardware.nixosModules; [
        common-pc
        common-cpu-intel
        common-pc-ssd
      ];
    })

    (mkHost {
      name = "nuc";
      system = "x86_64-linux";
      extraModules = with inputs.nixos-hardware.nixosModules; [
        common-pc
        common-cpu-intel
        common-pc-ssd
      ];
    })

    (mkHost {
      name = "mia0";
      system = "x86_64-linux";
    })

    (mkHost {
      name = "mtl0";
      system = "x86_64-linux";
    })

    (mkHost {
      name = "tencent";
      system = "x86_64-linux";
    })

    (mkHost {
      name = "hil0";
      system = "x86_64-linux";
    })

    (mkHost {
      name = "fsn0";
      system = "aarch64-linux";
    })
  ];
}
