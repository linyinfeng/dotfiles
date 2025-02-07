{
  config,
  pkgs,
  lib,
  ...
}:
let
  cfg = config.services.godns;

  godns = "${pkgs.godns}/bin/godns";

  godnsOpts =
    { name, config, ... }:
    {
      options = {
        name = lib.mkOption { type = with lib.types; str; };
        fullName = lib.mkOption { type = with lib.types; str; };
        settings = lib.mkOption { type = with lib.types; attrs; };
      };
      config = {
        name = lib.mkDefault name;
        fullName = lib.mkDefault "godns-${config.name}";
      };
    };
in
{
  options = {
    services.godns = lib.mkOption {
      default = { };
      type = with lib.types; attrsOf (submodule godnsOpts);
    };
  };
  config = {
    sops.secrets."cloudflare_token" = {
      # TODO wait for https://github.com/cloudflare/terraform-provider-cloudflare/issues/5045
      # terraformOutput.enable = true;
      sopsFile = config.sops-file.get "common.yaml";
      restartUnits = lib.mapAttrsToList (_: godnsCfg: "${godnsCfg.fullName}.service") cfg;
    };
    sops.templates = lib.mapAttrs' (
      _: godnsCfg:
      lib.nameValuePair "${godnsCfg.fullName}.json" {
        content = builtins.toJSON (
          lib.recursiveUpdate {
            provider = "Cloudflare";
            login_token = config.sops.placeholder."cloudflare_token";
            resolver = "8.8.8.8";
            debug_info = true;
          } godnsCfg.settings
        );
      }
    ) cfg;
    systemd.services = lib.mapAttrs' (
      _: godnsCfg:
      lib.nameValuePair godnsCfg.fullName {
        script = ''
          ${godns} -c ${config.sops.templates."${godnsCfg.fullName}.json".path}
        '';
        after = [ "network-online.target" ];
        requires = [ "network-online.target" ];
        wantedBy = [ "multi-user.target" ];
      }
    ) cfg;
  };
}
