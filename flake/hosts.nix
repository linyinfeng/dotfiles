{
  config,
  self,
  inputs,
  lib,
  getSystem,
  ...
}:
let
  buildSuites = profiles: f: lib.mapAttrs (_: lib.flatten) (lib.fix (f profiles));

  nixosModules = self.lib.buildModuleList ../nixos/modules;
  nixosProfiles = self.lib.rakeLeaves ../nixos/profiles;
  nixosSuites = buildSuites nixosProfiles (
    profiles: suites: {
      nixSettings = with profiles.nix; [
        gc
        settings
        cachix
        version
      ];
      base =
        suites.nixSettings
        ++ (with profiles; [
          boot.kernel
          boot.systemd-initrd
          services.openssh
          services.dbus
          services.oom-killer
          security.polkit
          security.rtkit
          security.sudo-rs
          global-persistence
          system.common
          system.sysrq
          users.root
        ]);

      network = with profiles; [
        networking.networkd
        networking.iproute2
        networking.firewall
        networking.avahi
        networking.resolved
        networking.tailscale
        networking.zerotier
        networking.mesh
        networking.dn42
        networking.endpoints
        security.fail2ban
        security.firewall
        services.vnstatd
      ];
      backup = with profiles; [ services.restic ];
      multimedia = with profiles; [
        graphical.gnome
        graphical.kde
        graphical.hyprland
        graphical.fonts
        graphical.i18n
        services.gnome-keyring
        services.pipewire
      ];
      development = with profiles; [
        development.shells
        development.documentation
        programs.adb
        programs.qrcp
        programs.ccache
        services.gnupg
        services.nixseparatedebuginfod
      ];
      multimediaDev = suites.multimedia ++ suites.development ++ (with profiles; [ development.ides ]);
      virtualization = with profiles; [
        virtualization.libvirt
        virtualization.podman
        virtualization.wine
      ];
      games = with profiles.graphical.game; [ steam ];
      monitoring = with profiles; [
        services.telegraf
        services.telegraf-system
        services.promtail
      ];

      workstation =
        (with suites; base ++ multimediaDev ++ virtualization ++ network ++ backup ++ monitoring)
        ++ (with profiles; [
          boot.binfmt
          system.types.workstation
          networking.network-manager
          networking.tools
          programs.tools
          programs.nix-index
          services.bluetooth
          services.auto-upgrade
          services.kde-connect
          services.printing
          services.snapper
          services.iperf3
          security.hardware-keys
          services.angrr
          hardware.rtl-sdr
          nix.nix-ld
          nix.hydra-builder-client
        ]);
      mobileWorkstation = suites.workstation;

      server =
        (with suites; base ++ network ++ backup ++ monitoring)
        ++ (with profiles; [
          system.types.server
          services.auto-upgrade
          services.bpftune
          services.iperf3
          networking.bbr
        ]);
      overseaServer = suites.server ++ (with profiles; [ services.bind ]);
      homeServer = suites.server ++ (with profiles; [ networking.network-manager ]);

      phone =
        (with suites; base ++ network)
        ++ (with profiles; [
          system.types.phone
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

      wsl =
        (with suites; base ++ network)
        ++ (with profiles; [
          system.types.workstation
          wsl.settings
        ])
        ++ [ inputs.nixos-wsl.nixosModules.wsl ];
    }
  );

  hmModules = self.lib.buildModuleList ../home-manager/modules;
  hmProfiles = self.lib.rakeLeaves ../home-manager/profiles;
  hmSuites = buildSuites hmProfiles (
    profiles: suites: {
      base = with profiles; [
        # nothing
      ];
      multimedia = with profiles; [
        gnome
        dconf-proxy
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
        git
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
      virtualization = [ ];
      multimediaDev =
        suites.multimedia
        ++ suites.development
        ++ (with profiles; [
          xdg-dirs
          vscode
          kitty
        ]);
      synchronize = with profiles; [
        onedrive
        digital-paper
      ];
      security = with profiles; [ gpg ];
      other = with profiles; [ hledger ];

      nonGraphical =
        with suites;
        base ++ development ++ virtualization ++ synchronize ++ security ++ other;

      full = with suites; base ++ multimediaDev ++ virtualization ++ synchronize ++ security ++ other;

      phone =
        (with suites; base)
        ++ (with profiles; [
          dconf-proxy
          firefox
          fcitx5
          development
          direnv
          shells
        ]);
    }
  );

  commonNixosModules = nixosModules ++ [
    inputs.sops-nix.nixosModules.sops
    inputs.impermanence.nixosModules.impermanence
    inputs.disko.nixosModules.disko
    inputs.flake-utils-plus.nixosModules.autoGenFromInputs
    inputs.linyinfeng.nixosModules.vlmcsd
    inputs.linyinfeng.nixosModules.tprofile
    inputs.linyinfeng.nixosModules.tg-send
    inputs.linyinfeng.nixosModules.dot-tar
    inputs.linyinfeng.nixosModules.matrix-media-repo
    inputs.oranc.nixosModules.oranc
    inputs.ace-bot.nixosModules.ace-bot
    inputs.commit-notifier.nixosModules.commit-notifier
    inputs.angrr.nixosModules.angrr
    inputs.hyprland.nixosModules.default

    {
      lib = {
        self = self.lib;
        nur = inputs.linyinfeng.lib;
      };
      home-manager = {
        sharedModules = commonHmModules;
        extraSpecialArgs = hmSpecialArgs;
      };
      system.configurationRevision = self.rev or null;
    }

    # TODO wait for https://nixpk.gs/pr-tracker.html?pr=299460
    (self.lib.replaceModuleSimple inputs.nixpkgs-hledger-web "services/web-apps/hledger-web.nix")
  ];

  commonHmModules = hmModules ++ [
    inputs.hyprland.homeManagerModules.default

    { lib.self = self.lib; }
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

  mkHost =
    {
      name,
      configurationName ? name,
      nixpkgs ? inputs.nixpkgs,
      home-manager ? inputs.home-manager,
      system,
      forceFlakeNixpkgs ? true,
      extraModules ? [ ],
    }:
    {
      ${name} = nixpkgs.lib.nixosSystem {
        specialArgs = nixosSpecialArgs;
        modules =
          commonNixosModules
          ++ [ home-manager.nixosModules.home-manager ]
          ++ extraModules
          ++ lib.optional (configurationName != null) ../nixos/hosts/${configurationName}
          ++ [
            (
              { lib, ... }:
              {
                networking.hostName = lib.mkDefault name;
              }
            )
            (
              if forceFlakeNixpkgs then
                {
                  imports = [ nixpkgs.nixosModules.readOnlyPkgs ];
                  nixpkgs = {
                    inherit ((getSystem system).allModuleArgs) pkgs;
                  };
                }
              else
                {
                  # crossOverlays has not been suppored by nixos module
                  nixpkgs =
                    let
                      nixpkgsArgs = (getSystem system).nixpkgs;
                    in
                    {
                      inherit (nixpkgsArgs) config overlays;
                    };
                }
            )
          ];
      };
    };

  mkHostAllSystems =
    { name }@args:
    lib.mkMerge (
      lib.lists.map (
        system:
        mkHost (
          args
          // {
            name = "${name}-${system}";
            configurationName = name;
            inherit system;
          }
        )
      ) config.systems
    );

  getHostToplevel =
    name: cfg:
    let
      inherit (cfg.pkgs.stdenv.hostPlatform) system;
    in
    {
      "${system}"."nixos/${name}" = cfg.config.system.build.toplevel;
    };
  hostToplevels = lib.fold lib.recursiveUpdate { } (
    lib.mapAttrsToList getHostToplevel self.nixosConfigurations
  );
in
{
  passthru = {
    inherit
      nixosProfiles
      nixosModules
      nixosSuites
      hmProfiles
      hmModules
      hmSuites
      ;
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
      extraModules = import "${inputs.mobile-nixos}/modules/module-list.nix" ++ [
        "${inputs.mobile-nixos}/devices/oneplus-enchilada"
        (
          { config, pkgs, ... }:
          {
            # TODO mobile-nixos tests `config.nixpkgs.localSystem`
            nixpkgs.system = "aarch64-linux";
          }
        )
      ];
    })

    (mkHost {
      name = "lax0";
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

    (mkHost {
      name = "framework-wsl";
      system = "x86_64-linux";
    })

    (mkHost {
      name = "duo";
      system = "riscv64-linux";
      extraModules = [
        "${inputs.nixos-riscv}/duo-256.nix"
        (
          { lib, ... }:
          {
            # readOnlyPkgs disables nixpkgs module
            # nixos-riscv sets `nixpkgs.crossSystem` and `nixpkgs.localSystem`
            options.nixpkgs = {
              localSystem = lib.mkSinkUndeclaredOptions { };
              crossSystem = lib.mkSinkUndeclaredOptions { };
            };
          }
        )
      ];
    })
    # PLACEHOLDER new host
  ];

  flake.checks = lib.recursiveUpdate hostToplevels {
    "aarch64-linux"."nixos/enchilada/android-bootimg" =
      self.nixosConfigurations.enchilada.config.mobile.outputs.android.android-bootimg;
    "riscv64-linux"."nixos/duo/sdImage" = self.nixosConfigurations.duo.config.system.build.sdImage;
  };
}
