{ ... }:
{
  programs.gpg = {
    enable = true;
    settings = {
      keyserver = "hkps://keys.openpgp.org";
      # pcscd only authorizes active sessions, so an agent autostarted from a
      # sessionless context (home-manager activation's `gpg --import`) lands in
      # system.slice, gets denied access_pcsc and breaks the smartcard.
      no-autostart = true;
    };
    scdaemonSettings = {
      # canokey support
      card-timeout = "5";
      disable-ccid = true;
    };
  };
}
