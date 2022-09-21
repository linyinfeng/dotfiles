{ ... }:

{
  ids.uids = {
    # human users
    yinfeng = 1000;
    nianyi = 1001;

    # other users
    nixos = 1099;

    # service users
    # nix-access-tokens = 400; # not using
    # nixbuild = 401; # not using
    # telegram-send = 402;
    # service-mail = 403;
    hydra-builder = 404;
  };
  ids.gids = {
    # service groups
    nix-access-tokens = 400;
    nixbuild = 401;
    telegram-send = 402;
    service-mail = 403;
    hydra-builder = 404;
  };
}
