# .wslconfig
# ==========
# [wsl2]
# networkingMode=mirrored
{...}: {
  wsl.wslConf = {
    interop.appendWindowsPath = false;
    network = {
      generateResolvConf = false;
      generateHosts = false;
    };
  };
  systemd.services.systemd-resolved.enable = true;
  services.resolved.extraConfig = ''
    MulticastDNS=resolve
  '';
}
