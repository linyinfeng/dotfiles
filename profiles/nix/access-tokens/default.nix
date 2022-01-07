{ config, ... }:

{
  nix.extraOptions = ''
    include ${config.sops.templates."nix-extra-config".path}
  '';
  nix.checkConfig = false;
  sops.templates."nix-extra-config".content = ''
    access-tokens = github.com=${config.sops.placeholder."nano/github-token"}
  '';
  sops.secrets."nano/github-token" = { };
}
