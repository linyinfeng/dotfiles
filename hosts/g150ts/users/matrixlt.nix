{ config, lib, ... }:

let
  groupNameIfPresent = name: lib.optional
    (config.users.groups ? ${name})
    config.users.groups.${name}.name;
in
{
  users.users.matrixlt = {
    passwordFile = config.sops.secrets."user-password/matrixlt".path;
    isNormalUser = true;
    extraGroups = with config.users.groups; [
      users.name
      wheel.name
    ] ++
    groupNameIfPresent "networkmanager" ++
    groupNameIfPresent "transmission";

    openssh.authorizedKeys.keyFiles =
      config.users.users.root.openssh.authorizedKeys.keyFiles;
  };

  sops.secrets."user-password/matrixlt".sopsFile = config.sops.secretsDir + /hosts/g150ts.yaml;
}
