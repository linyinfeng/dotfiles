{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (config.lib.self) data;
  issuer = data.zitadel_issuer;
  # OpenSSH strips environment variables before running AuthorizedKeysCommand,
  # so wrap opkssh with fw-proxy settings on hosts that route outbound traffic
  # through the local proxy.
  opksshPackage =
    if config.networking.fw-proxy.enable then
      pkgs.symlinkJoin {
        name = "opkssh-with-fw-proxy";
        paths = [ pkgs.opkssh ];
        nativeBuildInputs = [ pkgs.makeBinaryWrapper ];
        postBuild = ''
          wrapProgram $out/bin/opkssh \
            ${lib.concatStringsSep " \\\n  " (
              lib.mapAttrsToList (
                k: v: "--set-default ${lib.escapeShellArg k} ${lib.escapeShellArg v}"
              ) config.networking.fw-proxy.environment
            )}
        '';
      }
    else
      pkgs.opkssh;
  authorizedUsers = [ "root" ] ++ lib.optional (config.users.users ? yinfeng) "yinfeng";
in
{
  services.opkssh = {
    enable = true;
    package = opksshPackage;
    providers = {
      zitadel = {
        inherit issuer;
        clientId = data.zitadel_opkssh_client_id;
        lifetime = "24h";
      };
    };
    authorizations = map (user: {
      inherit user issuer;
      principal = data.zitadel_infra_admin_user_id;
    }) authorizedUsers;
  };
}
