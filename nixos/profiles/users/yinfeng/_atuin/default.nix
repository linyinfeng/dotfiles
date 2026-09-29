{ config, lib, ... }:
let
  name = "yinfeng";
  users = config.synchronize.users;
  enabled = users ? ${name} && users.${name}.enable;
in
lib.mkIf enabled {
  home-manager.users.${name} = {
    world.profiles.atuin.enable = true;

    home.env.secretPaths = {
      atuin_password_yinfeng = config.sops.secrets."atuin_password_yinfeng".path;
      yinfeng_atuin_key = config.sops.secrets."yinfeng_atuin_key".path;
    };
  };

  sops.secrets = {
    atuin_password_yinfeng = {
      terraformOutput.enable = true;
      owner = name;
      inherit (config.users.users.${name}) group;
    };
    yinfeng_atuin_key = {
      predefined.enable = true;
      owner = name;
      inherit (config.users.users.${name}) group;
    };
  };
}
