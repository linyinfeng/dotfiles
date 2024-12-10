{ config, pkgs, ... }:
let
  cfg = config.programs.ccache;
in
{
  programs.ccache = {
    enable = true;
    cacheDir = pkgs.ccacheCacheDir;
  };
  nix.settings.extra-sandbox-paths = [
    cfg.cacheDir
    pkgs.ccacheLogDir
  ];
  environment.global-persistence.directories = [ cfg.cacheDir ];
  systemd.tmpfiles.settings."50-ccache" = {
    ${cfg.cacheDir} = {
      d = {
        user = "root";
        group = "nixbld";
        mode = "0770";
      };
    };
    ${pkgs.ccacheLogDir} = {
      d = {
        user = "root";
        group = "nixbld";
        mode = "0750";
      };
    };
    "${pkgs.ccacheLogDir}/ccache.log" = {
      f = {
        user = "root";
        group = "nixbld";
        mode = "660";
      };
    };
  };
  services.logrotate.settings = {
    "${pkgs.ccacheLogDir}/ccache.log" = {
      create = "0660 root nixbld";
      size = "10M";
      compress = true;
      rotate = 1;
    };
  };
  nixpkgs.overlays = [
    (final: prev: {
      ccacheCacheDir = "/var/cache/ccache";
      ccacheLogDir = "/var/log/ccache";
      ccacheWrapper = prev.ccacheWrapper.override {
        extraConfig = ''
          export CCACHE_COMPRESS=1
          export CCACHE_UMASK=007
          if [ -d "${final.ccacheCacheDir}" ]; then
            export CCACHE_DIR="${final.ccacheCacheDir}"
          else
            export CCACHE_DIR="/tmp/ccache"
            mkdir -p "$CCACHE_DIR"
            echo "ccacheWrapper: \"${final.ccacheCacheDir}\" is not a directory, cache in \"$CCACHE_DIR\"" >&2
          fi
          if [ -d "${final.ccacheLogDir}" ]; then
            export CCACHE_LOGFILE="${final.ccacheLogDir}/ccache.log"
          fi
          if [ ! -w "$CCACHE_DIR" ]; then
            echo "ccacheWrapper: '$CCACHE_DIR' is not accessible for user $(whoami)" >&2
            exit 1
          fi
        '';
      };
      ccacheTest = final.ccacheStdenv.mkDerivation {
        name = "test-ccache";
        src = builtins.toFile "hello-world.c" ''
          #include <stdio.h>
          int main() { printf("hello, world\n"); }
        '';
        dontUnpack = true;
        env.NIX_DEBUG = 1;
        buildPhase = "cc $src -o hello";
        installPhase = "install -D hello $out/bin/hello";
      };
    })
  ];
}
