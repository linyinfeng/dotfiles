{
  description = "A highly structured configuration database.";

  inputs =
    {
      nixos.url = "github:nixos/nixpkgs/nixos-unstable";
      latest.url = "github:nixos/nixpkgs/master";
      digga = {
        url = "github:divnix/digga/develop";
        inputs.nipxkgs.follows = "latest";
        inputs.deploy.follows = "deploy";
      };
      bud.url = "github:divnix/bud"; # no need to follow nixpkgs: it never materialises
      deploy.url = "github:serokell/deploy-rs";
      deploy.inputs.nixpkgs.follows = "nixos";

      # remove after https://github.com/NixOS/nix/pull/4641
      nixpkgs.follows = "nixos";

      ci-agent = {
        url = "github:hercules-ci/hercules-ci-agent";
        inputs = { nix-darwin.follows = "darwin"; nixos-20_09.follows = "nixos"; nixos-unstable.follows = "latest"; };
      };
      darwin.url = "github:LnL7/nix-darwin";
      darwin.inputs.nixpkgs.follows = "latest";
      home.url = "github:nix-community/home-manager";
      home.inputs.nixpkgs.follows = "nixos";
      # naersk.url = "github:nmattia/naersk";
      # naersk.inputs.nixpkgs.follows = "latest";
      agenix.url = "github:ryantm/agenix";
      agenix.inputs.nixpkgs.follows = "latest";
      nixos-hardware.url = "github:nixos/nixos-hardware";

      nvfetcher.url = "github:berberman/nvfetcher";
      nvfetcher.inputs.nixpkgs.follows = "latest";

      # MAIN
      impermanence.url = "github:nix-community/impermanence";
      emacs-overlay.url = "github:nix-community/emacs-overlay";
      yinfeng.url = "github:linyinfeng/nur-packages";
    };

  outputs =
    { self
    , digga
    , bud
    , nixos
    , ci-agent
    , home
    , nixos-hardware
    , nur
    , agenix
    , nvfetcher
    , deploy
    , ...
    } @ inputs:
    let
      bud' = bud self; # rebind to access self.budModules
    in
    digga.lib.mkFlake
      {
        inherit self inputs;

        channelsConfig = { allowUnfree = true; };

        channels = {
          nixos = {
            imports = [ (digga.lib.importers.overlays ./overlays) ];
            overlays = [
              nur.overlay
              agenix.overlay
              nvfetcher.overlay
              deploy.overlay
              ./pkgs/default.nix

              # MAIN
              inputs.emacs-overlay.overlay
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
            imports = [ (digga.lib.importers.modules ./modules) ];
            externalModules = [
              { lib.our = self.lib; }
              ci-agent.nixosModules.agent-profile
              home.nixosModules.home-manager
              agenix.nixosModules.age
              (bud.nixosModules.bud bud')

              # MAIN
              inputs.impermanence.nixosModules.impermanence
              inputs.yinfeng.nixosModules.vlmcsd
            ];
          };

          imports = [ (digga.lib.importers.hosts ./hosts) ];
          hosts = {
            /* set host specific properties here */
            NixOS = { };

            # MAIN
            t460p = {
              modules = with nixos-hardware.nixosModules; [
                common-pc
                common-cpu-intel
                common-pc-ssd
                lenovo-thinkpad-t460s
              ];
            };
            xps8930 = {
              modules = with nixos-hardware.nixosModules; [
                common-pc
                common-cpu-intel
                common-pc-ssd
              ];
            };
          };
          importables = rec {
            profiles = digga.lib.importers.rakeLeaves ./profiles // {
              users = digga.lib.importers.rakeLeaves ./users;
            };
            suites = with profiles; rec {
              # MAIN
              foundation = [ global-persistence security.polkit services.gc services.openssh ];
              base = [ core foundation users.root ];

              network = (with networking; [ resolved tailscale ]) ++ (with security; [ fail2ban firewall ]);
              networkManager = (with networking; [ network-manager ]);
              multimedia = (with graphical; [ gnome fonts ibus-chinese ]) ++ (with services; [ pipewire ]);
              development = (with profiles.development; [ shells latex ]) ++ (with services; [ adb gnupg ]);
              multimediaDev = multimedia ++ development ++ (with profiles.development; [ ides ]);
              virtualization = with profiles.virtualization; [ docker libvirt wine anbox ];
              wireless = with services; [ bluetooth ];
              phone = with services; [ kde-connect ];
              printing = [ services.printing ];
              campus = with networking; [ campus-network ];

              ciAgent = with services; [ hercules-ci-agent ];
              fw = with networking; [ fw-proxy ];
              game = with graphical.game; [ steam ];
              chia = [ services.chia ];
              jupyterhub = [ services.jupyterhub ];
              transmission = [ services.transmission ];
              samba = [ services.samba ];
              godns = [ services.godns ];

              workstation = base ++ multimediaDev ++ virtualization ++ network ++ networkManager ++ wireless ++ phone ++ printing;
              mobileWorkstation = workstation ++ campus ++ [ laptop ];
              desktopWorkstation = workstation;
              homeServer = base ++ network ++ (with services; [ teamspeak vlmcsd ]);
              overseaServer = base ++ network;

              user-yinfeng = [ users.yinfeng ];
            };
          };
        };

        home = {
          imports = [ (digga.lib.importers.modules ./users/modules) ];
          externalModules = [
            # MAIN
            (builtins.toPath "${inputs.impermanence}/home-manager.nix")
          ];
          importables = rec {
            profiles = digga.lib.importers.rakeLeaves ./users/profiles;
            suites = with profiles; rec {
              # MAIN
              base = [ direnv git git-extra shells ];
              multimedia = [ gnome desktop-applications chromium firefox rime fonts ];
              development = [ profiles.development emacs tools asciinema ];
              virtualization = [ ];
              multimediaDev = multimedia ++ [ xdg-dirs ] ++ development ++ [ vscode ];
              synchronize = [ onedrive digital-paper ];

              full = base ++ multimediaDev ++ virtualization ++ synchronize;
            };
          };
        };

        devshell.modules = [ (import ./shell bud') ];

        homeConfigurations = digga.lib.mkHomeConfigurations self.nixosConfigurations;

        deploy.nodes = digga.lib.mkDeployNodes
          # MAIN
          (removeAttrs self.nixosConfigurations [ "NixOS" ])
          {
            sshUser = "root";
          };

        defaultTemplate = self.templates.bud;
        templates.bud.path = ./.;
        templates.bud.description = "bud template";

      }
    //
    {
      budModules = { devos = import ./pkgs/bud; };
    }
  ;
}
