{
  description = "A highly structured configuration database.";

  inputs =
    {
      nixos.url = "nixpkgs/nixos-unstable";
      latest.url = "nixpkgs";
      digga.url = "github:divnix/digga";

      ci-agent = {
        url = "github:hercules-ci/hercules-ci-agent";
        inputs = { nix-darwin.follows = "darwin"; nixos-20_09.follows = "nixos"; nixos-unstable.follows = "latest"; };
      };
      darwin.url = "github:LnL7/nix-darwin";
      darwin.inputs.nixpkgs.follows = "latest";
      home.url = "github:nix-community/home-manager";
      home.inputs.nixpkgs.follows = "nixos";
      naersk.url = "github:nmattia/naersk";
      naersk.inputs.nixpkgs.follows = "latest";
      nixos-hardware.url = "github:nixos/nixos-hardware";

      pkgs.url = "path:./pkgs";
      pkgs.inputs.nixpkgs.follows = "nixos";

      # MAIN
      impermanence.url = "github:nix-community/impermanence";
      emacs-overlay.url = "github:nix-community/emacs-overlay";
    };

  outputs = inputs@{ self, pkgs, digga, nixos, ci-agent, home, nixos-hardware, nur, ... }:
    digga.lib.mkFlake {
      inherit self inputs;

      channelsConfig = { allowUnfree = true; };

      channels = {
        nixos = {
          imports = [ (digga.lib.importers.overlays ./overlays) ];
          overlays = [
            ./pkgs/default.nix
            pkgs.overlay # for `srcs`
            nur.overlay

            # MAIN
            inputs.emacs-overlay.overlay
          ];
        };
        latest = { };
      };

      lib = import ./lib { lib = digga.lib // nixos.lib; };

      sharedOverlays = [
        (final: prev: {
          lib = prev.lib.extend (lfinal: lprev: {
            our = self.lib;
          });
        })
      ];

      nixos = {
        hostDefaults = {
          system = "x86_64-linux";
          channelName = "nixos";
          modules = ./modules/module-list.nix;
          externalModules = [
            { _module.args.ourLib = self.lib; }
            ci-agent.nixosModules.agent-profile
            home.nixosModules.home-manager
            ./modules/customBuilds.nix

            # MAIN
            inputs.impermanence.nixosModules.impermanence
          ];
        };

        imports = [ (digga.lib.importers.hosts ./hosts) ];
        hosts = {
          /* set host specific properties here */

          NixOS = { };
          # MAIN
          yinfeng-t460p = {
            modules = with nixos-hardware.nixosModules; [
              lenovo-thinkpad-t460s
              common-pc-ssd
            ];
          };
          yinfeng-work = {
            modules = with nixos-hardware.nixosModules; [
              common-pc
              common-cpu-intel
              common-pc-ssd
            ];
          };
        };
        profiles = [ ./profiles ./users ];
        suites = { profiles, users, ... }: with profiles; rec {
          base = [ core basic users.root users.yinfeng ];

          network = (with networking; [ network-manager resolved ]) ++ (with security; [ fail2ban firewall ]);
          multimedia = (with graphical; [ gnome fonts ibus-chinese ]) ++ (with services; [ sound ]);
          development = (with profiles.development; [ shells latex ]) ++ (with services; [ adb gnupg ]);
          multimediaDev = multimedia ++ development ++ (with profiles.development; [ ides ]);
          virtualization = with profiles.virtualization; [ docker libvirt wine anbox ];
          wireless = with services; [ bluetooth ];
          gfw = with networking; [ gfw-proxy ];
          campus = with networking; [ campus-network ];
          game = with graphical.game; [ steam ];
          ciAgent = with services; [ hercules-ci-agent ];
          phone = with services; [ kde-connect ];
          chia = [ services.chia ];

          workstation = base ++ multimediaDev ++ virtualization ++ network ++ wireless ++ phone ++ (with services; [ openssh printing ]);
          mobileWorkstation = workstation ++ campus ++ [ laptop ];
          desktopWorkstation = workstation ++ ciAgent;
        };
      };

      home = {
        modules = ./users/modules/module-list.nix;
        externalModules = [
          # MAIN
          (builtins.toPath "${inputs.impermanence}/home-manager.nix")
        ];
        profiles = [ ./users/profiles ];
        suites = { profiles, ... }: with profiles; rec {
          base = [ direnv git git-extra shells ];
          multimedia = [ gnome desktop-applications rime fonts ];
          development = [ profiles.development emacs tools asciinema ];
          virtualization = [ ];
          multimediaDev = multimedia ++ development ++ [ vscode ];
          synchronize = [ onedrive digital-paper ];

          full = base ++ multimediaDev ++ virtualization ++ synchronize;
        };
      };

      homeConfigurations = digga.lib.mkHomeConfigurations self.nixosConfigurations;

      deploy.nodes = digga.lib.mkDeployNodes self.nixosConfigurations { };

      defaultTemplate = self.templates.flk;
      templates.flk.path = ./.;
      templates.flk.description = "flk template";

    }
  ;
}
