{ ... }:
{
  ids.uids = {
    # human users
    yinfeng = 1000;
    nianyi = 1001;

    # other users
    agent = 1099;

    # operation users
    minecraft = 2000;

    # service users
    # nix-access-tokens = 400; # not using
    nixbuild = 401;
    # tg-send = 402;
    # service-mail = 403;
    # hydra-builder = 404; # replaced by the gRPC build agent
    # hydra-builder-client = 405;
    # windows = 406;
    steam = 407;
    cowrie = 408;
    sicp-staging = 409;
    # Workaround: static ID for opksshuser so environment.etc."opk/{providers,auth_id}".gid
    # can be set numerically under system.etc.overlay + services.userborn.
    # TODO: Remove once nixpkgs services.opkssh and system.etc.overlay / services.userborn
    # support non-root ownership for dynamically allocated users without numeric gid wiring.
    opksshuser = 410;
  };
  ids.gids = {
    # service groups
    nix-access-tokens = 400;
    nixbuild = 401;
    tg-send = 402;
    service-mail = 403;
    # hydra-builder = 404; # replaced by the gRPC build agent
    # hydra-builder-client = 405;
    windows = 406;
    steam = 407;
    cowrie = 408;
    sicp-staging = 409;
    # Workaround: static ID for opksshuser so environment.etc."opk/{providers,auth_id}".gid
    # can be set numerically under system.etc.overlay + services.userborn.
    # TODO: Remove once nixpkgs services.opkssh and system.etc.overlay / services.userborn
    # support non-root ownership for dynamically allocated users without numeric gid wiring.
    opksshuser = 410;
  };
}
