{
  config,
  lib,
  pkgs,
  ...
}:
let
  formats = {
    json = pkgs.formats.json { };
    yaml = pkgs.formats.yaml { };
  };

  # `*` merges recursively with the right operand winning, so the declared value
  # keeps the keys a tool wrote at runtime.
  mergers = {
    json = "${pkgs.jq}/bin/jq -s '.[0] * .[1]'";
    yaml = "${pkgs.yq-go}/bin/yq eval-all -o=yaml '. as $item ireduce ({}; . * $item)'";
  };

  mergeOpts =
    { name, ... }:
    {
      options = {
        format = lib.mkOption {
          type = lib.types.enum [
            "json"
            "yaml"
          ];
          default =
            if lib.hasSuffix ".json" name then
              "json"
            else if lib.hasSuffix ".yaml" name || lib.hasSuffix ".yml" name then
              "yaml"
            else
              throw "home.merge: set `format` for ${name}";
          description = "Serialization of the target file and of the generated value.";
        };

        value = lib.mkOption {
          type = lib.types.anything;
          description = "Contents the switch writes into the target file.";
        };
      };
    };

  mergeOne =
    name: cfg:
    let
      generated = formats.${cfg.format}.generate (baseNameOf name) cfg.value;
    in
    ''
      mergeHomeFile "$HOME/${name}" "${generated}" ${mergers.${cfg.format}}
    '';
in
{
  options.home.merge = lib.mkOption {
    type = lib.types.attrsOf (lib.types.submodule mergeOpts);
    default = { };
    description = ''
      Files to merge into instead of linking. A tool that rewrites its own
      config fails on a read-only symlink into the store, so the switch writes a
      real file: declared keys win, runtime-only keys survive until the next
      rebuild.
    '';
  };

  config.home.activation.mergeFiles = lib.hm.dag.entryAfter [ "linkGeneration" ] (
    lib.optionalString (config.home.merge != { }) ''
      mergeHomeFile() {
        local target="$1"
        local generated="$2"
        shift 2
        run mkdir -p "$(dirname "$target")"
        if [ -f "$target" ] && "$@" "$target" "$generated" > "$target.merged"; then
          run mv -f "$target.merged" "$target"
        else
          rm -f "$target.merged"
          warnEcho "$target is not parseable; replacing it with the declared value"
          # the generated file is 0444 in the store, the tool has to keep writing it
          run cp -f "$generated" "$target"
          run chmod u+w "$target"
        fi
      }
    ''
    + lib.concatLines (lib.mapAttrsToList mergeOne config.home.merge)
  );
}
