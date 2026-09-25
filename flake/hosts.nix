{
  config,
  self,
  inputs,
  lib,
  getSystem,
  ...
}:
let
  # Worlds: `modules` stays fully enabled, the preset trees are opt-in
  # (`world.<tree>.<path>.enable`), turned on by the suites and by `world.hosts.<name>.enable`.
  # Keyed by `<tree>.<leaf path>`.
  mkWorldAttrs =
    root: trees:
    lib.foldl' lib.mergeAttrs { } (
      lib.mapAttrsToList (
        tree: enable:
        let
          src = root + "/${tree}";
        in
        lib.listToAttrs (
          lib.zipListsWith (
            leaf: module: lib.nameValuePair "${lib.concatStringsSep "/" ([ tree ] ++ leaf.path)}" module
          ) (self.lib.mkWorldLeaves src) (self.lib.mkWorld { inherit src tree enable; })
        )
      ) trees
    );

  nixosWorld = mkWorldAttrs ../nixos {
    modules = true;
    profiles = false;
    suites = false;
    hosts = false;
  };
  hmWorld = mkWorldAttrs ../home-manager {
    modules = true;
    profiles = false;
    suites = false;
    users = false;
    standalone = false;
  };

  worldNixos = lib.attrValues nixosWorld;
  worldHm = lib.attrValues hmWorld;

  commonHmModules = worldHm;
  commonNixosModules = worldNixos ++ [
    {
      home-manager = {
        sharedModules = commonHmModules;
        extraSpecialArgs = commonSpecialArgs;
      };
      system.configurationRevision = self.rev or null;
    }
  ];

  commonSpecialArgs = {
    inherit inputs self;
  };

  mkStandaloneHm =
    {
      system,
      nixpkgs ? inputs.nixpkgs,
      home-manager ? inputs.home-manager,
      shapePath ? null,
      extraModules ? [ ],
    }:
    home-manager.lib.homeManagerConfiguration {
      pkgs = import nixpkgs {
        inherit system;
        inherit ((getSystem system).nixpkgs) config overlays;
      };
      extraSpecialArgs = commonSpecialArgs;
      modules =
        commonHmModules
        ++ lib.optional (shapePath != null) (
          lib.setAttrByPath (
            [
              "world"
              "standalone"
            ]
            ++ shapePath
            ++ [ "enable" ]
          ) true
        )
        ++ extraModules
        ++ [
          { home.stateVersion = self.lib.flakeStateVersion; }
        ];
    };

  standaloneHomeConfigurations = lib.mergeAttrsList (
    map (
      system:
      lib.listToAttrs (
        map (
          leaf:
          let
            name = lib.concatStringsSep "-" leaf.path;
          in
          lib.nameValuePair "${name}/${system}" (
            (mkStandaloneHm {
              inherit system;
              shapePath = leaf.path;
            })
            // {
              inherit name;
            }
          )
        ) (self.lib.mkWorldLeaves ../home-manager/standalone)
      )
    ) config.systems
  );

  # NixOS hosts see the whole world and enable themselves with `world.hosts.<name>.enable`.
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
        specialArgs = commonSpecialArgs;
        modules =
          commonNixosModules
          ++ [ home-manager.nixosModules.home-manager ]
          ++ extraModules
          ++ lib.optional (configurationName != null) {
            world.hosts.${configurationName}.enable = true;
          }
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
                  # crossOverlays has not been supported by nixos module
                  nixpkgs = {
                    inherit ((getSystem system).nixpkgs) config overlays;
                  };
                }
            )
          ];
      };
    };

  getHostToplevel =
    name: cfg:
    let
      inherit (cfg.pkgs.stdenv.buildPlatform) system;
    in
    {
      "${system}"."nixos/${name}" = cfg.config.system.build.toplevel;
    };
  hostToplevels = lib.foldr lib.recursiveUpdate { } (
    lib.mapAttrsToList getHostToplevel self.nixosConfigurations
  );

  getHomeActivation = cfg: {
    "${cfg.pkgs.stdenv.hostPlatform.system}"."home/${cfg.name}" = cfg.activationPackage;
  };
  homeActivations = lib.foldr lib.recursiveUpdate { } (
    lib.map getHomeActivation (lib.attrValues self.homeConfigurations)
  );
in
{
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
      name = "mtl0";
      system = "x86_64-linux";
    })
    (mkHost {
      name = "hkg0";
      system = "x86_64-linux";
    })
    # PLACEHOLDER new host

    # Disabled hosts. Their configs are kept as `nixos/hosts/_<name>/` (the `_` prefix keeps
    # them out of the world) and need the extra modules below before they can be re-enabled.
    #
    # (mkHost {
    #   name = "sparrow";
    #   system = "aarch64-linux";
    #   extraModules = [
    #     inputs.kukui-nixos.nixosModules.default
    #     "${inputs.kukui-nixos}/profiles/disko.nix"
    #     (
    #       { ... }:
    #       {
    #         passthru.sparrow-installer = inputs.kukui-nixos.nixosConfigurations.installer.extendModules {
    #           modules = [
    #             {
    #               environment.etc."system-to-install/source".source = "${self}";
    #               environment.etc."system-to-install/toplevel".source =
    #                 self.nixosConfigurations.sparrow.config.system.build.toplevel;
    #               environment.etc."system-to-install/scripts/destroy-format-mount".source =
    #                 self.nixosConfigurations.sparrow.config.system.build.destroyFormatMount;
    #               environment.etc."system-to-install/scripts/mount".source =
    #                 self.nixosConfigurations.sparrow.config.system.build.mount;
    #               kukui.disko = {
    #                 diskName = "installer";
    #                 device = "/dev/sda"; # usb drive
    #               };
    #             }
    #           ];
    #         };
    #       }
    #     )
    #   ];
    # })
  ];

  perSystem =
    { pkgs, ... }:
    let
      aggregateSecretsTemplates =
        input:
        pkgs.runCommandLocal "aggregate-secrets-templates-${input}" { } ''
          mkdir -p $out
          ${lib.concatMapAttrsStringSep "\n" (
            hostName: cfg:
            let
              secretTemplate = pkgs.writeTextFile {
                name = "secret-template-${hostName}-${input}";
                text = cfg.config.sops.extractTemplates.${input};
              };
            in
            ''
              cp "${secretTemplate}" "$out/${hostName}.yq"
            ''
          ) self.nixosConfigurations}
        '';
    in
    {
      packages."host-names" = pkgs.writeTextFile {
        name = "host-names";
        text = lib.concatStrings (lib.map (h: "${h}\n") (lib.attrNames self.nixosConfigurations));
      };
      packages."secrets-templates/terraform" = aggregateSecretsTemplates "terraformOutput";
      packages."secrets-templates/predefined" = aggregateSecretsTemplates "predefined";
    };

  flake.homeConfigurations = standaloneHomeConfigurations;

  flake.nixosModules = nixosWorld;
  flake.homeManagerModules = hmWorld;

  flake.checks = lib.mkMerge [
    hostToplevels
    homeActivations
  ];

  flake.libs.nixd =
    let
      dummySystem = "x86_64-linux";
      dummyPkgs = (getSystem dummySystem).allModuleArgs.pkgs;
    in
    {
      nixpkgs = dummyPkgs;
      nixosOptions =
        (mkHost {
          name = "nixd";
          configurationName = null;
          system = dummySystem;
        }).nixd.options;
      homeManagerOptions =
        (mkStandaloneHm {
          system = dummySystem;
          shapePath = [
            "yinfeng"
            "nonGraphical"
          ];
        }).options;
    };
}
