{
  self,
  lib,
  inputs,
  ...
}:
let
  mkNode =
    name: cfg:
    let
      inherit (cfg.pkgs.stdenv.hostPlatform) system;
      deployLib = inputs.deploy-rs.lib.${system};
    in
    {
      hostname = "${name}.ts.li7g.com";
      sshOpts = [
        "-p"
        "2222"
      ];
      # currently only a single profile system
      profilesOrder = [ "system" ];
      profiles.system = {
        sshUser = "root";
        user = "root";
        path = deployLib.activate.nixos cfg;
      };
    };
  isIndexed = name: self.lib.data.${name}.host_indices != [ ];
  nodes = lib.mapAttrs mkNode (lib.filterAttrs (name: _: isIndexed name) self.nixosConfigurations);
in
{
  flake = {
    deploy = {
      autoRollback = true;
      magicRollback = true;

      inherit nodes;
    };
  };
  perSystem =
    {
      config,
      system,
      pkgs,
      ...
    }:
    lib.mkMerge [
      (lib.mkIf (inputs.deploy-rs.lib ? ${system}) {
        # disabled
        # evaluation of deployChecks is slow
        # checks = inputs.deploy-rs.lib.${system}.deployChecks self.deploy;
      })
      (lib.mkIf config.isDevSystem {
        devshells.default = {
          commands = [
            {
              package = pkgs.deploy-rs.deploy-rs;
              name = "deploy";
              category = "deploy";
            }
          ];
        };
      })
    ];
}
