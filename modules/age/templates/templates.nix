{ config, pkgs, lib, ... }:
with lib;
with builtins;
let
  users = config.users.users;
  substitute = pkgs.writers.writePython3 "substitute" { }
    (replaceStrings [ "@subst@" ] [ "${subst-pairs}" ] (readFile ./subs.py));
  subst-pairs = pkgs.writeText "pairs" (concatMapStringsSep "\n"
    (name:
      "${config.age.placeholder.${name}} ${config.age.secrets.${name}.path}")
    (attrNames config.age.secrets));
  templateType = types.submodule ({ config, ... }: {
    options = {
      name = mkOption {
        type = types.str;
        default = config._module.args.name;
        description = ''
          Name of the file used in /run/secrets/files
        '';
      };
      path = mkOption {
        type = types.str;
        default = "/run/secrets/files/${config.name}";
      };
      content = mkOption {
        type = types.str;
        default = "";
        description = ''
          Content of the file
        '';
      };
      mode = mkOption {
        type = types.str;
        default = "0400";
        description = ''
          Permissions mode of the in octal.
        '';
      };
      owner = mkOption {
        type = types.str;
        default = "root";
        description = ''
          User of the file.
        '';
      };
      group = mkOption {
        type = types.str;
        default = users.${config.owner}.group;
        description = ''
          Group of the file.
        '';
      };
      file = mkOption {
        type = types.path;
        default = pkgs.writeText config.name config.content;
        visible = false;
        readOnly = true;
      };
    };
  });
in
{
  options.age = {
    templates = mkOption {
      type = types.attrsOf templateType;
      default = { };
    };
    placeholder = mkOption {
      type = types.attrsOf types.str;
      default =
        mapAttrs (name: _: "<AGE:${hashString "sha256" name}:PLACEHOLDER>")
          config.age.secrets;
      visible = false;
      readOnly = true;
    };
    substituteCmd = mkOption {
      type = types.path;
      default = substitute;
    };
  };

  config = mkIf (config.age.templates != { }) {
    system.activationScripts.agenix-templates = {
      text = ''
        echo "Setting up age templates..."
        ${concatMapStringsSep "\n" (name:
          let tpl = config.age.templates.${name};
          in ''
            mkdir -p "${dirOf tpl.path}"
            ${config.age.substituteCmd} ${tpl.file} > ${tpl.path}
            chmod "${tpl.mode}" "${tpl.path}"
            chown "${tpl.owner}" "${tpl.path}"
            chgrp "${tpl.group}" "${tpl.path}"
          '') (attrNames config.age.templates)}
      '';
      deps = [ "agenix" ];
    };
  };
}
