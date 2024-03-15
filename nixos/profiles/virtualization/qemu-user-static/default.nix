{
  config,
  pkgs,
  lib,
  ...
}:
lib.mkMerge [
  {
    systemd.services.qemu-user-static = {
      script = ''
        podman run \
          --rm --privileged \
          docker.io/multiarch/qemu-user-static \
          --reset --persistent yes
      '';
      path = with pkgs; [ podman ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
      };
      after = [ "network-online.target" ];
      requires = [ "network-online.target" ];
      wantedBy = [ "multi-user.service" ];
    };
  }
  {
    systemd.services.qemu-user-static = lib.mkIf (config.networking.fw-proxy.enable) {
      after = [ "fw-proxy.service" ];
      environment = lib.mkIf (config.networking.fw-proxy.enable) config.networking.fw-proxy.environment;
    };
  }
]
