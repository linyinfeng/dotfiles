{
  config,
  self,
  inputs,
  lib,
  withSystem,
  ...
}: let
  inherit (inputs.nixpkgs.lib) nixosSystem;
  inherit (inputs.digga.lib) rakeLeaves;
  buildSuites = profiles: f: lib.mapAttrs (_: lib.flatten) (lib.fix (f profiles));

  nixosModules = self.lib.buildModuleList ../nixos/modules;
  nixosProfiles = rakeLeaves ../nixos/profiles;
  nixosSuites = buildSuites nixosProfiles (profiles: suites: {
    core =
      suites.nixSettings
      ++ (with profiles; [
        programs.tools
        services.openssh
        system.sysrq
      ]);
    nixSettings = with profiles.nix; [gc settings cachix];
    base =
      suites.core
      ++ (with profiles; [
        security.polkit
        services.oom-killer
        global-persistence
        users.root
      ]);

    network = with profiles; [
      networking.avahi
      networking.resolved
      networking.tailscale
      networking.zerotier
      networking.tools
      security.fail2ban
      security.firewall
    ];
    backup = with profiles; [
      services.restic
    ];
    multimedia = with profiles; [
      graphical.gnome
      graphical.kde
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
  hmProfiles = rakeLeaves ../home-manager/profiles;
  hmSuites = buildSuites hmProfiles (profiles: suites: {
    base = with profiles; [git];
    multimedia = with profiles; [
      gnome
      sway
      desktop-applications
      chromium
      firefox
      rime
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
    ];
    virtualization = [];
    multimediaDev =
      suites.multimedia
      ++ suites.development
      ++ (with profiles; [xdg-dirs vscode]);
    synchronize = with profiles; [onedrive digital-paper];
    security = with profiles; [gpg];

    full = with suites;
      base
      ++ multimediaDev
      ++ virtualization
      ++ synchronize
      ++ security;
  });

  commonNixosModules =
    nixosModules
    ++ [
      inputs.home-manager.nixosModules.home-manager
      inputs.sops-nix.nixosModules.sops
      inputs.impermanence.nixosModules.impermanence
      inputs.nixos-cn.nixosModules.nixos-cn
      inputs.flake-utils-plus.nixosModules.autoGenFromInputs
      inputs.lanzaboote.nixosModules.lanzaboote
      inputs.linyinfeng.nixosModules.vlmcsd
      inputs.linyinfeng.nixosModules.tprofile
      inputs.linyinfeng.nixosModules.tg-send
      inputs.linyinfeng.nixosModules.commit-notifier
      inputs.linyinfeng.nixosModules.dot-tar

      {
        lib.self = self.lib;
        home-manager = {
          sharedModules = commonHmModules;
          extraSpecialArgs = hmSpecialArgs;
        };
      }

      # TODO wait for https://nixpk.gs/pr-tracker.html?pr=219315
      {
        disabledModules = [
          "i18n/input-method/fcitx5.nix"
          "i18n/input-method/ibus.nix"
        ];
        imports = [
          "${inputs.nixpkgs-rime-data}/nixos/modules/i18n/input-method/rime.nix"
          "${inputs.nixpkgs-rime-data}/nixos/modules/i18n/input-method/ibus.nix"
          "${inputs.nixpkgs-rime-data}/nixos/modules/i18n/input-method/fcitx5.nix"
        ];
      }
    ];

  commonHmModules =
    hmModules
    ++ [
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
    system,
    extraModules ? [],
  }: {
    ${name} = nixosSystem {
      inherit system;
      specialArgs = nixosSpecialArgs;
      pkgs = withSystem system ({pkgs, ...}: pkgs);
      modules =
        commonNixosModules
        ++ extraModules
        ++ [
          ../nixos/hosts/${name}

          ({lib, ...}: {
            networking.hostName = lib.mkDefault name;
          })
        ];
    };
  };
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
      name = "vultr";
      system = "x86_64-linux";
    })

    (mkHost {
      name = "rica";
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
  ];
}