{ config, lib, ... }:

let
  cfg = config.environment.shellAliases;
in

with lib;
{
  options.environment.shellAliases = lib.mkOption {
    type = with types; attrsOf str;
    default = { };
    description = ''
      An attribute set that maps aliases (the top level attribute names in this option) to command strings or directly to build outputs.
    '';
  };

  config = {
    programs = {
      bash.shellAliases = cfg;
      zsh.shellAliases = cfg;
      fish.shellAliases = cfg;
    };
  };
}
