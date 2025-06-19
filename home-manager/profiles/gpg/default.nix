{ ... }:
{
  programs.gpg = {
    enable = true;
    settings = {
      keyserver = "hkps://keys.openpgp.org";
    };
    scdaemonSettings = {
      # canokey support
      card-timeout = "5";
      disable-ccid = true;
    };
  };
}
