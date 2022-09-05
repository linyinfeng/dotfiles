{
  description = "A highly structured configuration database.";

  inputs =
    {
      nixos.url = "github:nixos/nixpkgs/nixos-unstable";
      latest.url = "github:nixos/nixpkgs/master";

      digga.url = "github:divnix/digga";
      digga.inputs.nixpkgs.follows = "nixos";
      digga.inputs.nixpkgs-unstable.follows = "nixos";
      digga.inputs.nixlib.follows = "nixos";
      digga.inputs.latest.follows = "latest";
      digga.inputs.home-manager.follows = "home";
      digga.inputs.deploy.follows = "deploy";
      digga.inputs.flake-compat.follows = "flake-compat";
      digga.inputs.devshell.follows = "devshell";

      devshell.url = "github:numtide/devshell";
      devshell.inputs.nixpkgs.follows = "nixos";
      devshell.inputs.flake-utils.follows = "digga/flake-utils-plus/flake-utils";

      beautysh.url = "github:lovesegfault/beautysh";
      beautysh.inputs.utils.follows = "digga/flake-utils-plus/flake-utils";
      beautysh.inputs.nixpkgs.follows = "nixos";

      home.url = "github:nix-community/home-manager";
      home.inputs.nixpkgs.follows = "nixos";
      home.inputs.utils.follows = "digga/flake-utils-plus/flake-utils";

      deploy.url = "github:serokell/deploy-rs";
      deploy.inputs.nixpkgs.follows = "nixos";
      deploy.inputs.utils.follows = "digga/flake-utils-plus/flake-utils";
      deploy.inputs.flake-compat.follows = "flake-compat";

      sops-nix.url = "github:Mic92/sops-nix";
      sops-nix.inputs.nixpkgs.follows = "nixos";

      nvfetcher.url = "github:berberman/nvfetcher";
      nvfetcher.inputs.nixpkgs.follows = "nixos";
      nvfetcher.inputs.flake-utils.follows = "digga/flake-utils-plus/flake-utils";
      nvfetcher.inputs.flake-compat.follows = "flake-compat";

      nixos-hardware.url = "github:nixos/nixos-hardware";

      nixos-generators.url = "github:nix-community/nixos-generators";
      nixos-generators.inputs.nixlib.follows = "nixos";
      nixos-generators.inputs.nixpkgs.follows = "nixos";

      impermanence.url = "github:nix-community/impermanence";
      linyinfeng.url = "github:linyinfeng/nur-packages";
      linyinfeng.inputs.flake-utils-plus.follows = "digga/flake-utils-plus";
      linyinfeng.inputs.nixpkgs.follows = "nixos";
      nix-gc-s3.url = "github:linyinfeng/nix-gc-s3";
      nix-gc-s3.inputs.nixpkgs.follows = "nixos";
      nix-gc-s3.inputs.flake-utils-plus.follows = "digga/flake-utils-plus";
      pastebin.url = "github:linyinfeng/pastebin";
      pastebin.inputs.nixpkgs.follows = "nixos";
      pastebin.inputs.flake-utils-plus.follows = "digga/flake-utils-plus";
      nixos-cn.url = "github:nixos-cn/flakes";
      nixos-cn.inputs.nixpkgs.follows = "nixos";
      nixos-cn.inputs.flake-utils.follows = "digga/flake-utils-plus/flake-utils";
      emacs-overlay.url = "github:nix-community/emacs-overlay";
      emacs-overlay.inputs.nixpkgs.follows = "nixos";
      emacs-overlay.inputs.flake-utils.follows = "digga/flake-utils-plus/flake-utils";
      emacs-webkit.url = "github:akirakyle/emacs-webkit";
      emacs-webkit.flake = false;
      nix.url = "github:nixos/nix";
      nix.inputs.nixpkgs.follows = "nixos";

      mc-config-nuc.url = "github:linyinfeng/mc-config-nuc";
      mc-config-nuc.inputs.nixpkgs.follows = "nixos";
      mc-config-nuc.inputs.flake-utils-plus.follows = "digga/flake-utils-plus";
      mc-config-nuc.inputs.mc-config.follows = "mc-config";
      mc-config-nuc.inputs.minecraft-nix.follows = "minecraft-nix";
      mc-config-nuc.inputs.minecraft-json.follows = "minecraft-json";
      mc-config.url = "github:linyinfeng/mc-config";
      mc-config.inputs.nixpkgs.follows = "nixos";
      mc-config.inputs.flake-utils-plus.follows = "digga/flake-utils-plus";
      mc-config.inputs.minecraft-nix.follows = "minecraft-nix";
      mc-config.inputs.minecraft-json.follows = "minecraft-json";
      minecraft-nix.url = "github:ninlives/minecraft.nix";
      minecraft-nix.inputs.nixpkgs.follows = "nixos";
      minecraft-nix.inputs.flake-utils.follows = "digga/flake-utils-plus/flake-utils";
      minecraft-nix.inputs.metadata.follows = "minecraft-json";
      minecraft-json.url = "github:ninlives/minecraft.json";
      minecraft-json.inputs.nixpkgs.follows = "nixos";
      minecraft-json.inputs.flake-utils.follows = "digga/flake-utils-plus/flake-utils";

      nix-index-database.url = "github:Mic92/nix-index-database";

      hydra.url = "github:nixos/hydra";
      # use hydra's bundled nix
      # hydra.inputs.nix.follows = "nix";
      hydra.inputs.nixpkgs.follows = "nixos";
      hydra.inputs.newNixpkgs.follows = "nixos";

      flake-compat.url = "github:edolstra/flake-compat";
      flake-compat.flake = false;
    };

  outputs =
    { self
    , digga
    , nixos
    , home
    , nixos-hardware
    , nvfetcher
    , deploy
    , ...
    } @ inputs:
    digga.lib.mkFlake
      {
        inherit self inputs;

        supportedSystems = [
          "x86_64-linux"
          # "aarch64-linux"
        ];

        channelsConfig = { allowUnfree = true; };

        channels = rec {
          nixos = {
            imports = [ (digga.lib.importOverlays ./overlays) ];
            overlays = [
              ./pkgs/default.nix
              nvfetcher.overlay
              deploy.overlay

              inputs.sops-nix.overlay
              inputs.nixos-cn.overlay
              inputs.linyinfeng.overlays.singleRepoNur
              inputs.emacs-overlay.overlay
              (final: prev:
                let
                  system = final.stdenv.hostPlatform.system;
                in
                {
                  nixVersions = prev.nixVersions.extend
                    (final': prev': {
                      master = inputs.nix.packages.${system}.nix;
                      selected = final'.unstable;
                    });
                  hydra-master = inputs.hydra.defaultPackage.${system};
                  nix-gc-s3 = inputs.nix-gc-s3.packages.${system}.nix-gc-s3;
                  pastebin = inputs.pastebin.packages.${system}.default;
                  mc-config-nuc = inputs.mc-config-nuc.packages.${system};
                  nix-index-database = inputs.nix-index-database.legacyPackages.${system}.database;
                })
            ];
          };
          latest = { };
        };

        lib = import ./lib { lib = digga.lib // nixos.lib; };

        sharedOverlays = [
          (final: prev: {
            __dontExport = true;
            lib = prev.lib.extend (lfinal: lprev: {
              our = self.lib;
            });
          })
        ];

        nixos = {
          hostDefaults = {
            system = "x86_64-linux";
            channelName = "nixos";
            imports = [ (digga.lib.importExportableModules ./modules) ];
            modules = [
              { lib.our = self.lib; }
              digga.nixosModules.bootstrapIso
              digga.nixosModules.nixConfig
              home.nixosModules.home-manager

              inputs.sops-nix.nixosModules.sops
              inputs.impermanence.nixosModules.impermanence
              inputs.nixos-cn.nixosModules.nixos-cn
              inputs.linyinfeng.nixosModules.vlmcsd
              inputs.linyinfeng.nixosModules.tprofile
              inputs.linyinfeng.nixosModules.telegram-send
              inputs.linyinfeng.nixosModules.commit-notifier
              inputs.linyinfeng.nixosModules.dot-tar
            ];
          };

          imports = [ (digga.lib.importHosts ./hosts) ];
          hosts = {
            /* set host specific properties here */
            NixOS = {
              tests = import ./lib/tests;
            };
            t460p = {
              system = "x86_64-linux";
              modules = with nixos-hardware.nixosModules; [
                common-pc
                common-cpu-intel
                common-pc-ssd
                lenovo-thinkpad-t460s
              ];
              tests = import ./lib/tests;
            };
            xps8930 = {
              system = "x86_64-linux";
              modules = with nixos-hardware.nixosModules; [
                common-pc
                common-cpu-intel
                common-pc-ssd
              ];
              tests = import ./lib/tests;
            };
            x200s = {
              system = "x86_64-linux";
              modules = with nixos-hardware.nixosModules; [
                common-pc
                common-cpu-intel
                common-pc-ssd
              ];
              tests = import ./lib/tests;
            };
            nuc = {
              system = "x86_64-linux";
              modules = with nixos-hardware.nixosModules; [
                common-pc
                common-cpu-intel
                common-pc-ssd
              ];
              tests = import ./lib/tests;
            };
            vultr = {
              system = "x86_64-linux";
              tests = import ./lib/tests;
            };
            rica = {
              system = "x86_64-linux";
              tests = import ./lib/tests;
            };
            tencent = {
              system = "x86_64-linux";
              tests = import ./lib/tests;
            };
            g150ts = {
              system = "x86_64-linux";
              tests = import ./lib/tests;
            };
          };
          importables = rec {
            profiles = digga.lib.rakeLeaves ./profiles // {
              users = digga.lib.rakeLeaves ./users;
            };
            suites = nixos.lib.fix (suites: {
              core = suites.nixSettings ++ (with profiles; [ programs.tools services.openssh ]);
              nixSettings = with profiles.nix; [ gc settings version cachix ];
              base = suites.core ++
                (with profiles; [
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
                graphical.v4l2
                services.pipewire
              ];
              development = with profiles; [
                development.shells
                services.adb
                services.gnupg
              ];
              multimediaDev = suites.multimedia ++ suites.development ++
                (with profiles; [ development.ides ]);
              virtualization = with profiles; [
                virtualization.libvirt
                virtualization.wine
                virtualization.podman
              ];
              games = with profiles.graphical.game; [ steam minecraft ];
              monitoring = with profiles; [
                services.telegraf-system
                services.promtail
              ];

              workstation = [
                profiles.system.types.workstation
              ] ++ (with suites; [
                base
                multimediaDev
                virtualization
                network
                backup
                monitoring
              ]) ++ (with profiles; [
                networking.network-manager
                services.bluetooth
                services.auto-upgrade
                services.kde-connect
                services.printing
                security.hardware-keys
                hardware.rtl-sdr
                nix.nix-ld
              ]);
              mobileWorkstation = suites.workstation ++
                (with profiles; [
                  services.tlp
                ]);

              server = [
                profiles.system.types.server
              ] ++ (with suites; [
                base
                network
                backup
                monitoring
              ]) ++
              (with profiles; [
                services.auto-upgrade
              ]);
              homeServer = suites.server ++
                (with profiles; [
                  networking.network-manager
                ]);
            });
          };
        };

        home = {
          imports = [ (digga.lib.importExportableModules ./users/modules) ];
          modules = [ ];
          importables = rec {
            profiles = digga.lib.rakeLeaves ./users/profiles;
            suites = nixos.lib.fix (suites: {
              base = with profiles; [ direnv git shells ];
              multimedia = with profiles; [ gnome sway desktop-applications chromium firefox rime fonts mime obs-studio ];
              development = with profiles; [ development emacs tools tex postmarketos awscli terraform ];
              virtualization = [ ];
              multimediaDev = suites.multimedia ++ suites.development ++
                (with profiles; [ xdg-dirs vscode ]);
              synchronize = with profiles; [ onedrive digital-paper ];
              security = with profiles; [ gpg ];

              full = with suites; base ++ multimediaDev ++ virtualization ++ synchronize ++ security;
            });
          };
          users = digga.lib.rakeLeaves ./users/hm;
        };

        devshell = ./shell;

        homeConfigurations = digga.lib.mkHomeConfigurations self.nixosConfigurations;

        deploy.nodes =
          let
            inherit (nixos) lib;
            disabledHosts = [ "NixOS" "bootstrap" "x200s" "g150ts" ];
            configs = lib.filterAttrs (name: cfg: !(lib.elem name disabledHosts)) self.nixosConfigurations;
          in
          digga.lib.mkDeployNodes
            configs
            (lib.mapAttrs
              (name: cfg: {
                hostname = "${cfg.config.networking.hostName}.zt.li7g.com";
              })
              configs);
        deploy.sshUser = "root";

        templates.default = self.templates.project;
        templates.project.path = ./templates/project;
        templates.project.description = "simple project template";

        outputsBuilder = channels:
          let
            pkgs = channels.nixos;
            inherit (pkgs) system lib;
          in
          {
            checks =
              deploy.lib.${system}.deployChecks self.deploy //
              (
                lib.foldl lib.recursiveUpdate { }
                  (lib.mapAttrsToList
                    (host: cfg:
                      lib.optionalAttrs (cfg.pkgs.system == system)
                        { "toplevel-${host}" = cfg.config.system.build.toplevel; })
                    self.nixosConfigurations)
              ) // (
                lib.mapAttrs'
                  (name: drv: lib.nameValuePair "package-${name}" drv)
                  self.packages.${system}
              ) // {
                devShell = self.devShell.${system};
              };

            hydraJobs = self.checks.${system} // {
              all-checks = pkgs.linkFarm "all-checks"
                (lib.mapAttrsToList (name: drv: { inherit name; path = drv; })
                  self.checks.${system});
            };
          };
      };
}
