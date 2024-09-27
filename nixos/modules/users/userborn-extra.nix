{ config, lib, ... }:
let
  entries =
    kindLetter:
    lib.concatLists (
      lib.mapAttrsToList (
        _: userCfg:
        lib.lists.map (
          rangeCfg: "${userCfg.name}:${toString rangeCfg."start${kindLetter}id"}:${toString rangeCfg.count}"
        ) userCfg."sub${kindLetter}idRanges"
      ) config.users.users
    );
  mkIdRangeFile = kindLetter: lib.concatStringsSep "\n" (entries kindLetter) + "\n";
in
{
  environment.etc."subuid".text = mkIdRangeFile "U";
  environment.etc."subgid".text = mkIdRangeFile "G";
}
