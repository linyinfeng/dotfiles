{ ... }:
{
  ids.uids = {
    # human users
    yinfeng = 1000;
    nianyi = 1001;

    # other users
    nixos = 1099;

    # operation users
    minecraft = 2000;

    # service users
    # nix-access-tokens = 400; # not using
    nixbuild = 401;
    # tg-send = 402;
    # service-mail = 403;
    hydra-builder = 404;
    hydra-builder-client = 405;
    # windows = 406;
    steam = 407;
  };
  ids.gids = {
    # service groups
    nix-access-tokens = 400;
    nixbuild = 401;
    tg-send = 402;
    service-mail = 403;
    hydra-builder = 404;
    hydra-builder-client = 405;
    windows = 406;
    steam = 407;
  };
}
