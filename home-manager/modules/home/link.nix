{
  config,
  lib,
  ...
}: let
  linkOpts = {name, ...}: {
    options = {
      target = lib.mkOption {
        type = with lib.types; path;
        description = ''
          The target file.
        '';
      };
    };
  };
in {
  options.home.link = lib.mkOption {
    type = with lib.types; attrsOf (submodule linkOpts);
    default = {};
  };
  config = {
    home.activation.linkFiles = let
      linkOne = path: cfg: ''
        mkdir -p "$HOME/${dirOf path}"
        ln -sf "${cfg.target}" "$HOME/${path}"
      '';
      script = lib.concatStrings (lib.mapAttrsToList linkOne config.home.link);
    in
      lib.hm.dag.entryAfter ["writeBoundary"] script;
  };
}
