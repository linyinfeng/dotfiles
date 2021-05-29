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
      sops-nix = {
        url = "github:Mic92/sops-nix";
        inputs.nixpkgs.follows = "nixos";
      };
      flake-utils.url = "github:numtide/flake-utils";
      yinfeng = {
        url = "github:linyinfeng/nur-packages";
        inputs.nixpkgs.follows = "nixos";
        inputs.flake-utils.follows = "flake-utils";
      };
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
            inputs.sops-nix.overlay
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
            inputs.sops-nix.nixosModules.sops
            inputs.yinfeng.nixosModules.vlmcsd
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
          foundation = [ global-persistence sops security.polkit services.clean-gcroots ];
          base = [ core foundation users.root ];

          network = (with networking; [ resolved tailscale ]) ++ (with security; [ fail2ban firewall ]) ++ (with services; [ openssh ]);
          networkManager = (with networking; [ network-manager ]);
          multimedia = (with graphical; [ gnome fonts ibus-chinese ]) ++ (with services; [ sound ]);
          development = (with profiles.development; [ shells latex ]) ++ (with services; [ adb gnupg ]);
          multimediaDev = multimedia ++ development ++ (with profiles.development; [ ides ]);
          virtualization = with profiles.virtualization; [ docker libvirt wine anbox ];
          wireless = with services; [ bluetooth ];
          phone = with services; [ kde-connect ];
          printing = [ services.printing ];
          campus = with networking; [ campus-network ];
          ciAgent = with services; [ hercules-ci-agent ];

          gfw = with networking; [ gfw-proxy ];
          game = with graphical.game; [ steam ];
          chia = [ services.chia ];
          jupyterhub = [ services.jupyterhub ];

          workstation = base ++ multimediaDev ++ virtualization ++ network ++ networkManager ++ wireless ++ phone ++ printing;
          mobileWorkstation = workstation ++ campus ++ [ laptop ];
          desktopWorkstation = workstation ++ ciAgent;
          homeServer = base ++ network ++ (with services; [ teamspeak vlmcsd ]);
          overseaServer = base ++ network;

          user-yinfeng = [ users.yinfeng ];
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

      deploy.nodes = digga.lib.mkDeployNodes
        # MAIN
        (removeAttrs self.nixosConfigurations [ "NixOS" ])
        {
          sshUser = "root";
        };

      defaultTemplate = self.templates.flk;
      templates.flk.path = ./.;
      templates.flk.description = "flk template";

    }
  ;
}
