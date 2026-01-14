{ config, lib, ... }:
let
  inherit (config.networking) hostName;
  globalConfig = config;
  terraformOutputOpts =
    { config, ... }:
    {
      options = {
        terraformOutput = {
          enable = lib.mkEnableOption "extract from terraform output";
          perHost = lib.mkEnableOption "extract form host output";
          yqPath = lib.mkOption {
            type = lib.types.str;
            default =
              if config.terraformOutput.perHost then
                ".hosts.value.${hostName}.${config.name}"
              else
                ".${config.name}.value";
          };
        };
        predefined = {
          enable = lib.mkEnableOption "extract from predefined sops file";
          yqPath = lib.mkOption {
            type = lib.types.str;
            default = ".${config.name}";
          };
        };
      };
      config = lib.mkMerge [
        (lib.mkIf config.terraformOutput.enable { sopsFile = globalConfig.sops-file.terraform; })
        (lib.mkIf config.predefined.enable { sopsFile = globalConfig.sops-file.predefined; })
      ];
    };
in
{
  options = {
    sops.secrets = lib.mkOption { type = with lib.types; attrsOf (submodule terraformOutputOpts); };
    sops.extractTemplates = {
      terraformOutput = lib.mkOption { type = lib.types.lines; };
      predefined = lib.mkOption { type = lib.types.lines; };
    };
  };
  config = {
    sops.extractTemplates = {
      terraformOutput = ''
        { ${
          lib.concatMapStringsSep "\n, " (cfg: ''"${cfg.name}": ${cfg.terraformOutput.yqPath}'') (
            lib.attrValues (lib.filterAttrs (_: c: c.terraformOutput.enable) config.sops.secrets)
          )
        } }
      '';
      predefined = ''
        { ${
          lib.concatMapStringsSep "\n, " (cfg: ''"${cfg.name}": ${cfg.predefined.yqPath}'') (
            lib.attrValues (lib.filterAttrs (_: c: c.predefined.enable) config.sops.secrets)
          )
        } }
      '';
    };
  };
}
