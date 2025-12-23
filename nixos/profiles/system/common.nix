{ lib, ... }:

{
  i18n.defaultLocale = lib.mkDefault "en_US.UTF-8";
  i18n.extraLocales = "all"; # for locale testing
  console.keyMap = lib.mkDefault "us";
  time.timeZone = lib.mkDefault "Asia/Shanghai";
  users.mutableUsers = lib.mkDefault false;
}
