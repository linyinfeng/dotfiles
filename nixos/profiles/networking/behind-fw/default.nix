{ ... }:
let

  mkMirror = url: {
    inherit url;
    # below cache.nixos.org's 10, so mirrors win a latency tie
    priority = 9;
    public_key = "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY=";
  };
in
{
  services.ncro.settings.upstreams = [
    (mkMirror "https://mirror.nju.edu.cn/nix-channels/store")
    (mkMirror "https://mirrors.ustc.edu.cn/nix-channels/store")
  ];
}
