{ config, pkgs, lib, ... }:

let
  cfg = config.services.godns;

  godns = "${pkgs.nur.repos.linyinfeng.godns}/bin/godns";

  godnsOpts = { name, config, ... }: {
    options = {
      name = lib.mkOption {
        type = with lib.types; str;
      };
      fullName = lib.mkOption {
        type = with lib.types; str;
      };
      settings = lib.mkOption {
        type = with lib.types; attrs;
      };
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
    age.secrets.cloudflare-token.file = ../../../secrets/cloudflare-token.age;
    age.templates = lib.mapAttrs'
      (_: godnsCfg:
        lib.nameValuePair godnsCfg.fullName
          {
            content = builtins.toJSON (lib.recursiveUpdate
              {
                provider = "Cloudflare";
                login_token = config.age.placeholder.cloudflare-token;
                resolver = "8.8.8.8";
              }
              godnsCfg.settings);
          })
      cfg;
    systemd.services = lib.mapAttrs'
      (_: godnsCfg:
        lib.nameValuePair godnsCfg.fullName
          {
            script = ''
              ${godns} -c ${config.age.templates.${godnsCfg.fullName}.path}
            '';
            after = [ "network-online.target" ];
            wantedBy = [ "multi-user.target" ];
          })
      cfg;
  };
}


# age.templates.${fullName}.content = builtins.toJSON (lib.mkMerge [
#   {
#     provider = "Cloudflare";
#     login_token = config.age.templates.${fullName}.placeholder;
#     resolver = "8.8.8.8";
#   }
#   godnsCfg.settings
# ]);
# systemd.services.${fullName} = {
#   script = ''
#     ${pkgs.godns} -c ${config.age.templates.${fullName}.path}
#   '';
#   wantedBy = [ "network.target" ];
# };
