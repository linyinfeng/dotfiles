{
  description = "A highly structured configuration database.";

  nixConfig.extra-experimental-features = "nix-command flakes";
  nixConfig.extra-substituters = "https://linyinfeng.cachix.org https://nix-community.cachix.org";
  nixConfig.extra-trusted-public-keys = "linyinfeng.cachix.org-1:sPYQXcNrnCf7Vr7T0YmjXz5dMZ7aOKG3EqLja0xr9MM= nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs=";

  inputs =
    {
      nixos.url = "github:nixos/nixpkgs/nixos-unstable";
      latest.url = "github:nixos/nixpkgs/master";

      digga.url = "github:divnix/digga";
      digga.inputs.nixpkgs.follows = "nixos";
      digga.inputs.nixlib.follows = "nixos";
      digga.inputs.latest.follows = "latest";
      digga.inputs.home-manager.follows = "home";
      digga.inputs.deploy.follows = "deploy";

      bud.url = "github:divnix/bud";
      bud.inputs.nixpkgs.follows = "nixos";
      bud.inputs.devshell.follows = "digga/devshell";

      home.url = "github:nix-community/home-manager";
      home.inputs.nixpkgs.follows = "nixos";

      darwin.url = "github:LnL7/nix-darwin";
      darwin.inputs.nixpkgs.follows = "nixos";

      deploy.url = "github:input-output-hk/deploy-rs";
      deploy.inputs.nixpkgs.follows = "nixos";
      deploy.inputs.utils.follows = "digga/flake-utils-plus/flake-utils";
      fenix.url = "github:nix-community/fenix";
      fenix.inputs.nixpkgs.follows = "nixos";
      deploy.inputs.fenix.follows = "fenix";

      # MAIN switch to sops-nix and remove agenix
      agenix.url = "github:ryantm/agenix";
      agenix.inputs.nixpkgs.follows = "nixos";
      sops-nix.url = "github:Mic92/sops-nix";
      sops-nix.inputs.nixpkgs.follows = "nixos";

      nvfetcher.url = "github:berberman/nvfetcher";
      nvfetcher.inputs.nixpkgs.follows = "nixos";
      nvfetcher.inputs.flake-utils.follows = "digga/flake-utils-plus/flake-utils";

      naersk.url = "github:nmattia/naersk";
      naersk.inputs.nixpkgs.follows = "nixos";

      nixos-hardware.url = "github:nixos/nixos-hardware";

      # MAIN: more inputs follows
      bud.inputs.beautysh.follows = "beautysh";
      beautysh.url = "github:lovesegfault/beautysh";
      beautysh.inputs.flake-utils.follows = "digga/flake-utils-plus/flake-utils";
      beautysh.inputs.nixpkgs.follows = "nixos";

      # MAIN
      nur.url = "github:nix-community/nur";
      impermanence.url = "github:nix-community/impermanence";
      linyinfeng.url = "github:linyinfeng/nur-packages";
      linyinfeng.inputs.flake-utils-plus.follows = "digga/flake-utils-plus";
      linyinfeng.inputs.nixpkgs.follows = "nixos";
      nixos-cn.url = "github:nixos-cn/flakes";
      nixos-cn.inputs.nixpkgs.follows = "nixos";
      nixos-cn.inputs.flake-utils.follows = "digga/flake-utils-plus/flake-utils";
      emacs-overlay.url = "github:nix-community/emacs-overlay";
      emacs-webkit.url = "github:akirakyle/emacs-webkit";
      emacs-webkit.flake = false;
      nix.url = "github:nixos/nix";
      nix.inputs.nixpkgs.follows = "nixos";

      flake-compat.url = "github:edolstra/flake-compat";
      flake-compat.flake = false;
      deploy.inputs.flake-compat.follows = "flake-compat";
      nvfetcher.inputs.flake-compat.follows = "flake-compat";
    };

  outputs =
    { self
    , digga
    , bud
    , nixos
    , home
    , nixos-hardware
    , nur
    , agenix
    , nvfetcher
    , deploy
    , ...
    } @ inputs:
    digga.lib.mkFlake
      {
        inherit self inputs;

        # TODO devShell borken on aarch64-linux
        supportedSystems = [
          "x86_64-linux"
          # "aarch64-linux"
        ];

        channelsConfig = { allowUnfree = true; };

        channels = rec {
          nixos = {
            imports = [ (digga.lib.importOverlays ./overlays) ];
            overlays = [
              # TODO nix flake show broken due to IFD
              # nur.overlay
              agenix.overlay
              nvfetcher.overlay
              deploy.overlay
              ./pkgs/default.nix

              # MAIN
              inputs.sops-nix.overlay
              inputs.nixos-cn.overlay
              inputs.linyinfeng.overlays.singleRepoNur
              inputs.emacs-overlay.overlay
              (final: prev: {
                nixUnstable = inputs.nix.packages.${final.stdenv.hostPlatform.system}.nix;
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
              agenix.nixosModules.age
              bud.nixosModules.bud

              # MAIN
              inputs.sops-nix.nixosModules.sops
              inputs.impermanence.nixosModules.impermanence
              inputs.nixos-cn.nixosModules.nixos-cn
              # "${inputs.nixos-cn}/modules/sops/template"
              # "${inputs.nixos-cn}/modules/sops/extend-scripts.nix"
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

            # MAIN
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
            nexusbytes = {
              system = "x86_64-linux";
              tests = import ./lib/tests;

            };
          };
          importables = rec {
            profiles = digga.lib.rakeLeaves ./profiles // {
              users = digga.lib.rakeLeaves ./users;
            };
            suites = with profiles; rec {
              # MAIN
              foundation = [ global-persistence security.polkit services.gc services.openssh nix.access-tokens ];
              base = [ core foundation users.root ];

              audit = [ security.audit ];
              network = (with networking; [ tailscale zerotier tools ]) ++ (with security; [ fail2ban firewall ]);
              networkManager = (with networking; [ network-manager ]);
              multimedia = (with graphical; [ gnome kde sway fonts i18n v4l2 ]) ++ (with services; [ pipewire ]);
              development = (with profiles.development; [ shells latex ]) ++ (with services; [ adb gnupg ]);
              multimediaDev = multimedia ++ development ++ (with profiles.development; [ ides ]);
              # podman disabled
              virtualization = with profiles.virtualization; [ libvirt wine ];

              resolved = [ networking.resolved ];
              wireguardHome = [ networking.wireguard-home ];
              wireless = with services; [ bluetooth ];
              phone = with services; [ kde-connect ];
              printing = [ services.printing ];
              acme = [ services.acme ];
              telegramSend = [ programs.telegram-send ];
              notifyFailure = [ services.notify-failure ];
              fw = with networking; [ fw-proxy ];
              tpm = [ security.tpm ];
              nixbuild = [ nix.nixbuild ];
              game = with graphical.game; [ steam minecraft ];
              chia = [ services.chia ];
              transmission = [ services.transmission ];
              samba = [ services.samba ];
              godns = [ services.godns ];
              waydroid = [ profiles.virtualization.waydroid ];
              telegrafSystem = [ services.telegraf-system ];
              promtail = [ services.promtail ];
              monitoring = [ telegrafSystem promtail ];
              canokey = [ security.canokey ];
              autoUpgrade = [ services.auto-upgrade ];
              teamspeak = [ services.teamspeak ];
              vlmcsd = [ services.vlmcsd ];
              syncthing = [ services.syncthing ];

              workstation = base ++ multimediaDev ++ virtualization ++ network ++ networkManager ++ wireless ++ phone ++ telegramSend ++ notifyFailure ++ printing ++ canokey;
              mobileWorkstation = workstation ++ [ laptop ];
              desktopWorkstation = workstation;
              server = base ++ network;
              homeServer = server ++ networkManager ++ godns ++ teamspeak ++ vlmcsd;

              userYinfeng = [ users.yinfeng ];
              userNianyi = [ users.nianyi ];
            };
          };
        };

        home = {
          imports = [ (digga.lib.importExportableModules ./users/modules) ];
          modules = [
            # TODO nix flake show broken due to IFD
            # see https://github.com/nix-community/home-manager/issues/1262
            { manual.manpages.enable = false; }
          ];
          importables = rec {
            profiles = digga.lib.rakeLeaves ./users/profiles;
            suites = with profiles; rec {
              # MAIN
              base = [ direnv git git-extra shells ];
              multimedia = [ gnome sway desktop-applications chromium firefox rime fonts mime obs-studio ];
              development = [ profiles.development emacs tools asciinema tex postmarketos ];
              virtualization = [ ];
              multimediaDev = multimedia ++ [ xdg-dirs ] ++ development ++ [ vscode ];
              synchronize = [ onedrive digital-paper roaming ];
              security = [ gpg ];

              full = base ++ multimediaDev ++ virtualization ++ synchronize ++ security;
            };
          };
          users = {
            nixos = { suites, ... }: { imports = suites.base; };
          }; # digga.lib.importers.rakeLeaves ./users/hm;
        };

        devshell = ./shell;

        homeConfigurations = digga.lib.mkHomeConfigurations self.nixosConfigurations;

        deploy.nodes = digga.lib.mkDeployNodes
          # MAIN
          (removeAttrs self.nixosConfigurations [ "NixOS" "bootstrap" ])
          {
            vultr.hostname = "vultr.ts.li7g.com";
            nexusbytes.hostname = "nexusbytes.ts.li7g.com";
            x200s.hostname = "x200s.ts.li7g.com";
            nuc.hostname = "nuc.ts.li7g.com";
            t460p.hostname = "t460p.ts.li7g.com";
            xps8930.hostname = "xps8930.ts.li7g.com";
          };
        deploy.sshUser = "root";

        defaultTemplate = self.templates.bud;
        templates.bud.path = ./.;
        templates.bud.description = "bud template";
        # MAIN
        templates.project.path = ./templates/project;
        templates.project.description = "simple project template";

        # MAIN
        outputsBuilder = channels:
          let
            pkgs = channels.nixos;
            inherit (pkgs) system lib;
          in
          {
            checks = (
              # fix preferLocalBuild for deployChecks
              let
                deployChecks = deploy.lib.${system}.deployChecks self.deploy;
                renameOp = n: v: { name = "deploy-" + n; value = deployChecks.${n}; };
                localBuild = n: v: v.overrideAttrs (oldAttrs:
                  assert ! (oldAttrs ? preferLocalBuild); {
                    preferLocalBuild = true;
                  });
              in
              lib.mapAttrs localBuild (lib.mapAttrs' renameOp deployChecks)
            ) //
            (
              lib.foldl lib.recursiveUpdate { }
                (lib.mapAttrsToList
                  (host: cfg:
                    lib.optionalAttrs (cfg.pkgs.system == system)
                      { "toplevel-${host}" = cfg.config.system.build.toplevel; })
                  self.nixosConfigurations)
            ) // {
              devShell = self.devShell.${system};
            };


            hydraJobs = {
              all-checks = pkgs.linkFarm "all-checks"
                (lib.mapAttrsToList (name: drv: { inherit name; path = drv; })
                  self.checks.${system});
            } // self.checks.${system};
          };
      }
    //
    {
      budModules = { devos = import ./shell/bud; };
    }
  ;
}
