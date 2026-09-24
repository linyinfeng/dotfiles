{ ... }:
{
  home.username = "yinfeng";
  home.homeDirectory = "/home/yinfeng";

  programs.git.settings = {
    user.name = "Lin Yinfeng";
    user.email = "lin.yinfeng@outlook.com";
    # do not sign by default
    # signing.signByDefault = true;
  };
  programs.gpg.publicKeys = [
    {
      source = ./_pgp/pub.asc;
      trust = "ultimate";
    }
  ];
}
