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
  authorizedUsers = [
    "root"
  ]
  ++ lib.optional config.world.profiles.users.yinfeng.enable "yinfeng"
  ++ lib.optional config.world.profiles.users.agent.enable "agent";
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

  # Workaround: services.homed defaults services.userdbd.enableSSHSupport to
  # config.services.openssh.enable, which sets services.openssh.authorizedKeysCommand
  # to userdbctl and conflicts with services.opkssh (OpenSSH only supports a single
  # AuthorizedKeysCommand). None of our hosts currently rely on systemd-homed for
  # SSH authorized keys, so disable userdbd SSH integration in favor of opkssh.
  # TODO: Remove once OpenSSH / NixOS supports composing multiple
  # AuthorizedKeysCommand providers (or switch to a composite command wrapper if
  # systemd-homed SSH key lookup is ever needed alongside opkssh).
  services.userdbd.enableSSHSupport = false;

  # Workaround: nixpkgs' services.opkssh only sets string user/group on
  # /etc/opk/{providers,auth_id} (mode 0640). Under system.etc.overlay +
  # services.userborn, build-composefs-dump.py ignores string user/group and
  # only honors numeric uid/gid (defaulting to 0:0), which leaves both files
  # 0640 root:root and unreadable by opksshuser. Bind static IDs for opksshuser
  # and wire the numeric gid while keeping uid = 0 (root) to match upstream
  # opkssh's expected 0640 root:opksshuser ownership.
  # TODO: Remove once nixpkgs services.opkssh and system.etc.overlay /
  # services.userborn support non-root ownership for dynamically allocated users
  # (or upstream stops relying on 0640 environment.etc entries with string group).
  users.users.opksshuser.uid = config.ids.uids.opksshuser;
  users.groups.opksshuser.gid = config.ids.gids.opksshuser;
  environment.etc."opk/providers".gid = config.ids.gids.opksshuser;
  environment.etc."opk/auth_id".gid = config.ids.gids.opksshuser;
}
