{
  config,
  self,
  inputs,
  lib,
  getSystem,
  ...
}: let
  buildSuites = profiles: f: lib.mapAttrs (_: lib.flatten) (lib.fix (f profiles));

  nixosModules = self.lib.buildModuleList ../nixos/modules;
  nixosProfiles = self.lib.rakeLeaves ../nixos/profiles;
  nixosSuites = buildSuites nixosProfiles (profiles: suites: {
    nixSettings = with profiles.nix; [gc settings cachix version];
    base =
      suites.nixSettings
      ++ (with profiles; [
        programs.tools
        programs.nix-index
        services.openssh
        services.dbus
        services.oom-killer
        security.polkit
        security.rtkit
        global-persistence
        system.common
        system.sysrq
        users.root
      ]);

    network = with profiles; [
      networking.firewall
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
      programs.qrcp
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

    phone =
      (with suites; base ++ network)
      ++ (with profiles; [
        system.types.phone
        graphical.gnome
        graphical.fonts
        graphical.i18n
        development.shells
        services.gnupg
        services.pipewire
        services.kde-connect
        services.printing
        services.bluetooth
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
      chromium
      firefox
      rime
      fcitx5
      mime
      obs-studio
      minecraft
      desktop-applications
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
      awscli
      terraform
      shells
    ];
    virtualization = [];
    multimediaDev =
      suites.multimedia
      ++ suites.development
      ++ (with profiles; [xdg-dirs vscode kitty]);
    synchronize = with profiles; [onedrive digital-paper];
    security = with profiles; [gpg];
    other = with profiles; [hledger];

    nonGraphical = with suites;
      base
      ++ development
      ++ virtualization
      ++ synchronize
      ++ security
      ++ other;

    full = with suites;
      base
      ++ multimediaDev
      ++ virtualization
      ++ synchronize
      ++ security
      ++ other;

    phone =
      (with suites; base)
      ++ (with profiles; [
        gnome
        firefox
        rime
        fcitx5
        development
        direnv
        shells
      ]);
  });

  commonNixosModules =
    nixosModules
    ++ [
      inputs.sops-nix.nixosModules.sops
      inputs.impermanence.nixosModules.impermanence
      inputs.disko.nixosModules.disko
      inputs.flake-utils-plus.nixosModules.autoGenFromInputs
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
        system.constant = true;
        # system.configurationRevision = self.rev or null;
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
    nixpkgs ? inputs.nixpkgs,
    home-manager ? inputs.home-manager,
    system,
    forceFlakeNixpkgs ? true,
    extraModules ? [],
  }: {
    ${name} = nixpkgs.lib.nixosSystem {
      specialArgs = nixosSpecialArgs;
      modules =
        commonNixosModules
        ++ [home-manager.nixosModules.home-manager]
        ++ extraModules
        ++ lib.optional (configurationName != null) ../nixos/hosts/${configurationName}
        ++ [
          ({lib, ...}: {
            networking.hostName = lib.mkDefault name;
            nixpkgs = {inherit system;};
          })
          (
            if forceFlakeNixpkgs
            then {
              _module.args.pkgs = lib.mkForce (getSystem system).allModuleArgs.pkgs;
            }
            else {
              nixpkgs = {
                inherit (config.nixpkgs) config overlays;
              };
            }
          )
        ];
    };
  };

  mkHostAllSystems = {name} @ args:
    lib.mkMerge (
      lib.lists.map
      (system:
        mkHost (args
          // {
            name = "${name}-${system}";
            configurationName = name;
            inherit system;
          }))
      config.systems
    );

  getHostToplevel = name: cfg: let
    inherit (cfg.pkgs.stdenv.hostPlatform) system;
  in {
    "${system}"."nixos/${name}" = cfg.config.system.build.toplevel;
  };
  hostToplevels =
    lib.fold lib.recursiveUpdate {}
    (lib.mapAttrsToList getHostToplevel self.nixosConfigurations);
in {
  passthru = {
    inherit nixosProfiles nixosModules nixosSuites hmProfiles hmModules hmSuites;
  };

  flake.nixosConfigurations = lib.mkMerge [
    (mkHost {
      name = "framework";
      system = "x86_64-linux";
      extraModules = with inputs.nixos-hardware.nixosModules; [
        inputs.lanzaboote.nixosModules.lanzaboote
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
      name = "enchilada";
      system = "aarch64-linux";
      forceFlakeNixpkgs = false;
      extraModules =
        import "${inputs.mobile-nixos}/modules/module-list.nix"
        ++ [
          "${inputs.mobile-nixos}/devices/oneplus-enchilada"
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
      name = "shg0";
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

    (mkHost {
      name = "hkg0";
      system = "x86_64-linux";
    })
  ];

  flake.checks = lib.recursiveUpdate hostToplevels {
    "aarch64-linux"."nixos/enchilada/android-bootimg" = self.nixosConfigurations.enchilada.config.mobile.outputs.android.android-bootimg;
  };
}
