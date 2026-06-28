{ pkgs, ... }:
let
  skills = pkgs.symlinkJoin {
    name = "skills";
    paths = [ pkgs.linyinfeng.codestable ];
  };
in
{
  home.file.".config/opencode/skills" = {
    source = toString skills;
    recursive = true;
  };
}
