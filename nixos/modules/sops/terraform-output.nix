{
  config,
  lib,
  ...
}: let
  inherit (config.networking) hostName;
  globalConfig = config;
  terraformOutputOpts = {config, ...}: {
    options.terraformOutput = {
      enable = lib.mkEnableOption "extraction from terraform output";
      perHost = lib.mkEnableOption "extract form host output";
      yqPath = lib.mkOption {
        type = lib.types.str;
        default =
          if config.terraformOutput.perHost
          then ".hosts.value.${hostName}.${config.name}"
          else ".${config.name}.value";
      };
    };
    config = lib.mkIf config.terraformOutput.enable {
      sopsFile = globalConfig.sops-file.terraform;
    };
  };
  secretsFromOutputs = lib.filterAttrs (_: c: c.terraformOutput.enable) config.sops.secrets;
in {
  options = {
    sops.secrets = lib.mkOption {
      type = with lib.types; attrsOf (submodule terraformOutputOpts);
    };
    sops.terraformTemplate = lib.mkOption {
      type = lib.types.lines;
    };
  };
  config = {
    sops.terraformTemplate = ''
      { ${lib.concatMapStringsSep "\n, " (cfg: ''"${cfg.name}": ${cfg.terraformOutput.yqPath}'') (lib.attrValues secretsFromOutputs)} }
    '';
  };
}
