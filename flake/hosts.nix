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
        cache
        version
        access-tokens
      ];
      base =
        suites.nixSettings
        ++ (with profiles; [
          boot.kernel.latest
          boot.systemd-initrd
          services.openssh
          services.dbus
          security.polkit
          security.rtkit
          security.sudo-rs
          global-persistence
          system.constant
          system.common
          system.sysrq
          system.perlless
          system.oomd
          system.panic
          development.shells
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
        graphical.niri
        graphical.fonts
        i18n.input-method
        services.gnome-keyring
        services.pipewire
      ];
      development = with profiles; [
        development.documentation
        programs.adb
        programs.qrcp
        services.gnupg
        services.nixseparatedebuginfod

        services.envfs
        programs.nix-alien
        nix.nix-ld
      ];
      multimediaDev = suites.multimedia ++ suites.development ++ (with profiles; [ development.ides ]);
      virtualization = with profiles; [
        virtualization.libvirt
        virtualization.podman
        virtualization.wine
        virtualization.incus
      ];
      games = with profiles.graphical.game; [
        steam
        gamescope
      ];
      monitoring = with profiles; [
        services.telegraf
        services.telegraf-system
        services.promtail
      ];

      workstation =
        (with suites; base ++ multimediaDev ++ virtualization ++ network ++ backup ++ monitoring)
        ++ (with profiles; [
          boot.binfmt
          boot.plymouth
          system.types.workstation
          networking.network-manager
          networking.tools
          networking.mobile-nixos-usb
          programs.terminal-multiplexing
          programs.tools
          programs.nix-index
          programs.solaar
          programs.service-mail
          programs.tg-send
          programs.localsend
          services.bluetooth
          services.auto-upgrade
          services.kde-connect
          services.printing
          services.snapper
          services.iperf3
          services.angrr
          services.homed
          services.portal-client
          services.ssh-honeypot
          services.flatpak
          services.smartd
          audio.midi
          security.hardware-keys
          hardware.rtl-sdr
          hardware.tablet
          nix.nixbuild
          nix.hydra-builder-client
          nix.hydra-builder-server
          nix.auto-gen
        ]);
      mobileWorkstation =
        suites.workstation
        ++ (with profiles; [
          networking.behind-fw
          networking.fw-proxy
          graphical.graphical-powersave-target
        ]);

      server =
        (with suites; base ++ network ++ backup ++ monitoring)
        ++ (with profiles; [
          system.types.server
          services.auto-upgrade
          services.bpftune
          services.iperf3
          programs.terminal-multiplexing
          networking.bbr
        ]);
      overseaServer = suites.server ++ (with profiles; [ services.bind ]);
      homeServer = suites.server ++ (with profiles; [ networking.network-manager ]);
      embeddedServer =
        (with suites; base ++ network)
        ++ (with profiles; [
          system.types.server
          networking.bbr
        ]);

      mobile =
        (with suites; base ++ network)
        ++ (with profiles; [
          boot.plymouth
          system.types.phone
          graphical.fonts
          i18n.input-method
          programs.tools
          programs.nix-index
          programs.localsend
          development.shells
          services.flatpak
          services.gnupg
          services.pipewire
          services.kde-connect
          services.printing
          services.bluetooth
          security.hardware-keys
          networking.network-manager
        ]);

      wsl =
        (with suites; base ++ network)
        ++ (with profiles; [
          system.types.workstation
          i18n.input-method
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
        niri
        darkman
        dconf-proxy
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
        ssh
        pssh
        tools
        tex
        awscli
        terraform
        shells
        ok
        vscode-server
        terminal-multiplexing
      ];
      music = [
        profiles.music
      ];
      design = with profiles; [
        blender
      ];
      virtualization = [ ];
      multimediaDev =
        suites.multimedia
        ++ suites.development
        ++ (with profiles; [
          xdg-dirs
          vscode
          alacritty
          wezterm
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

      full =
        with suites;
        base ++ multimediaDev ++ music ++ design ++ virtualization ++ synchronize ++ security ++ other;

      mobile =
        with suites;
        base
        ++ security
        ++ other
        ++ (with profiles; [
          dconf-proxy
          chromium
          rime
          mime

          # development
          git
          development
          direnv
          ssh
          shells

          # multimediaDev
          xdg-dirs
        ]);
    }
  );

  commonNixosModules = nixosModules ++ [
    inputs.sops-nix.nixosModules.sops
    inputs.preservation.nixosModules.preservation
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
    inputs.lanzaboote.nixosModules.lanzaboote
    inputs.nix-topology.nixosModules.default
    inputs.niri-flake.nixosModules.niri

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
  ];

  commonHmModules = hmModules ++ [
    inputs.nixos-vscode-server.homeModules.default
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
                  nixpkgs = {
                    inherit ((getSystem system).nixpkgs) config overlays;
                  };
                }
            )
          ];
      };
    };

  # deadnix: skip
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
      inherit (cfg.pkgs.stdenv.buildPlatform) system;
    in
    {
      "${system}"."nixos/${name}" = cfg.config.system.build.toplevel;
    };
  hostToplevels = lib.fold lib.recursiveUpdate { } (
    lib.mapAttrsToList getHostToplevel self.nixosConfigurations
  );

  # deadnix: skip
  mkReplaceModule =
    nixpkgs: module:
    { modulesPath, ... }:
    {
      disabledModules = [
        "${modulesPath}/${module}"
      ];
      imports = [
        "${nixpkgs}/nixos/modules/${module}"
      ];
    };
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
      name = "parrot";
      system = "x86_64-linux";
      extraModules = with inputs.nixos-hardware.nixosModules; [
        common-pc
        common-pc-ssd
        common-cpu-amd
        common-cpu-amd-pstate
        common-gpu-amd
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
      name = "sparrow";
      system = "aarch64-linux";
      extraModules = [
        inputs.kukui-nixos.nixosModules.default
        "${inputs.kukui-nixos}/profiles/disko.nix"
        (
          { ... }:
          {
            passthru.sparrow-installer = inputs.kukui-nixos.nixosConfigurations.installer.extendModules {
              modules = [
                {
                  environment.etc."system-to-install/source".source = "${self}";
                  environment.etc."system-to-install/toplevel".source =
                    self.nixosConfigurations.sparrow.config.system.build.toplevel;
                  environment.etc."system-to-install/scripts/destroy-format-mount".source =
                    self.nixosConfigurations.sparrow.config.system.build.destroyFormatMount;
                  environment.etc."system-to-install/scripts/mount".source =
                    self.nixosConfigurations.sparrow.config.system.build.mount;
                  kukui.disko = {
                    diskName = "installer";
                    device = "/dev/sda"; # usb drive
                  };
                }
              ];
            };
          }
        )
      ];
    })

    (mkHost {
      name = "enchilada";
      system = "aarch64-linux";
      forceFlakeNixpkgs = false;
      extraModules = import "${inputs.mobile-nixos}/modules/module-list.nix" ++ [
        "${inputs.mobile-nixos}/devices/oneplus-enchilada"
        (
          { ... }:
          {
            # mobile-nixos tests `config.nixpkgs.localSystem`
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
      name = "fsn0";
      system = "aarch64-linux";
    })

    (mkHost {
      name = "hkg0";
      system = "x86_64-linux";
    })
    # PLACEHOLDER new host
  ];

  flake.checks = lib.recursiveUpdate hostToplevels {
    # TODO fix
    # "aarch64-linux" = {
    #   "android-boot-image/enchilada" = self.nixosConfigurations.enchilada.config.system.build.bootImage;
    #   "linux/enchilada" = self.nixosConfigurations.enchilada.config.boot.kernelPackages.kernel;
    # };
    "x86_64-linux" = {
      "linux/parrot" = self.nixosConfigurations.parrot.config.boot.kernelPackages.kernel;
    };
  };
}
