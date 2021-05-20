{ config, lib, ... }:

let

  secretOpts = { name, ... }: {
    options = {
      secret = lib.mkOption {
        type = with lib.types; str;
        description = ''
          The target secret.
        '';
      };
    };
  };

in
{
  options.home.linkSecrets = lib.mkOption {
    type = with lib.types; attrsOf (submodule secretOpts);
    default = { };
  };
  config = {
    home.activation.linkSecrets =
      let
        linkOne = path: cfg: ''
          mkdir -p "$HOME/${dirOf path}"
          ln -sf "${cfg.secret}" "$HOME/${path}"
        '';
        script = lib.concatStrings (lib.mapAttrsToList linkOne config.home.linkSecrets);
      in
      lib.hm.dag.entryAfter [ "writeBoundary" ] script;
  };
}
