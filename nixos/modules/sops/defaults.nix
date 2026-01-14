{ config, lib, ... }:
let
  inherit (config.networking) hostName;
in
{
  options.sops-file = {
    directory = lib.mkOption { type = lib.types.path; };
    get = lib.mkOption { type = with lib.types; functionTo path; };
    predefined = lib.mkOption { type = lib.types.path; };
    terraform = lib.mkOption { type = lib.types.path; };
  };
  config = {
    sops-file.directory = lib.mkDefault ../../../secrets;
    sops-file.get = p: "${config.sops-file.directory}/${p}";
    sops-file.predefined = config.sops-file.get "predefined/hosts/${hostName}.yaml";
    sops-file.terraform = config.sops-file.get "terraform/hosts/${hostName}.yaml";

    sops.gnupg.sshKeyPaths = [ ];
    sops.age = {
      sshKeyPaths = [ ];
      keyFile = lib.mkDefault (
        if config.environment.global-persistence.enable then
          "/persist/var/lib/sops-nix/key"
        else
          "/var/lib/sops-nix/key"
      );
    };
  };
}
