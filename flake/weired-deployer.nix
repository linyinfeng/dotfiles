{
  self,
  inputs,
  lib,
  ...
}:
let
  isIndexed = name: self.lib.data.hosts.${name}.host_indices != [ ];
  hosts = lib.mapAttrs mkHost (lib.filterAttrs (name: _: isIndexed name) self.nixosConfigurations);
  mkHost = _name: _cfg: { };
in
{
  debug = true;
  perSystem =
    {
      config,
      pkgs,
      lib,
      ...
    }:
    let
      weirdDeployer = inputs.weird-deployer.lib.weirdDeployer { inherit pkgs lib; };
      wdCfg = weirdDeployer {
        modules = [
          {
            deployer = {
              identifier = "dotfiles";
              flake = "${self}";
              inherit hosts;
              syncOn = {
                # fully parallel evaluate + build + copy
                evaluated = false;
                built = false;
                # only sync on copied and tested
              };
            };
          }
        ];
      };
    in
    (lib.mkIf config.isDevSystem { packages.weird-deployer = wdCfg.config.build.deployer; });
}
