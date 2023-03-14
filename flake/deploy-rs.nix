{
  self,
  lib,
  inputs,
  withSystem,
  ...
}: let
  mkNode = name: cfg: let
    inherit (cfg.pkgs.stdenv.hostPlatform) system;
    deployLib = inputs.deploy-rs.lib.${system};
  in {
    hostname = "${name}.ts.li7g.com";
    # currently only a single profile system
    profilesOrder = ["system"];
    profiles.system = {
      sshUser = "root";
      user = "root";
      path = deployLib.activate.nixos cfg;
    };
  };
  nodes = lib.mapAttrs mkNode self.nixosConfigurations;
in {
  flake = {
    deploy = {
      autoRollback = true;
      magicRollback = true;

      inherit nodes;
    };
  };
  perSystem = {system, ...}: {
    checks = inputs.deploy-rs.lib.${system}.deployChecks self.deploy;
  };
}
