{ ... }:
let

  mkMirror = url: {
    inherit url;
    priority = 30;
    public_key = "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY=";
  };
in
{
  services.ncro.settings.upstreams = [
    (mkMirror "https://mirror.nju.edu.cn/nix-channels/store")
    (mkMirror "https://mirrors.ustc.edu.cn/nix-channels/store")
    (mkMirror "https://mirrors.cernet.edu.cn/nix-channels/store")
  ];
}
