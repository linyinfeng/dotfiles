{
  config,
  inputs,
  getSystem,
  ...
}: let
  packages = [
    inputs.sops-nix.overlays.default
    inputs.nixos-cn.overlay
    inputs.linyinfeng.overlays.singleRepoNur
    inputs.oranc.overlays.default
    inputs.ace-bot.overlays.default
    inputs.emacs-overlay.overlay
    inputs.hyprland.overlays.default
    inputs.hyprwm-contrib.overlays.default
    inputs.attic.overlays.default
    inputs.flat-flake.overlays.default
    (final: prev: let
      inherit (prev.stdenv.hostPlatform) system;
      inherit ((getSystem system).allModuleArgs) inputs';
    in {
      nixVersions =
        prev.nixVersions.extend
        (final': prev': {
          master = inputs'.nix.packages.nix;
          selected = final'.stable;
        });
      nix-gc-s3 = inputs'.nix-gc-s3.packages.nix-gc-s3;
      pastebin = inputs'.pastebin.packages.default;
      mc-config-nuc = inputs'.mc-config-nuc.packages;
      nix-index-with-db = inputs'.nix-index-database.packages.nix-index-with-db;

      # ccache
      ccacheCacheDir = "/var/cache/ccache";
      ccacheLogDir = "/var/log/ccache";
      ccacheWrapper = prev.ccacheWrapper.override {
        extraConfig = ''
          export CCACHE_COMPRESS=1
          export CCACHE_DIR="${final.ccacheCacheDir}"
          export CCACHE_LOGFILE="${final.ccacheLogDir}/ccache.log"
          export CCACHE_UMASK=007
          if [ ! -d "$CCACHE_DIR" ]; then
            echo "ccacheWrapper: '$CCACHE_DIR' does not exist" >&2
            exit 1
          fi
          if [ ! -w "$CCACHE_DIR" ]; then
            echo "ccacheWrapper: '$CCACHE_DIR' is not accessible for user $(whoami)" >&2
            exit 1
          fi
          if [ ! -f "$CCACHE_LOGFILE" ]; then
            echo "ccacheWrapper: '$CCACHE_LOGFILE' does not exist" >&2
            exit 1
          fi
          if [ ! -w "$CCACHE_LOGFILE" ]; then
            echo "ccacheWrapper: '$CCACHE_LOGFILE' is not accessible for user $(whoami)" >&2
            exit 1
          fi
        '';
      };

      # adjustment
      comma = prev.comma.override {
        nix-index-unwrapped = final.nix-index-with-db;
      };
      gnuradio = prev.gnuradio.override {
        unwrapped = prev.gnuradio.unwrapped.override {
          stdenv = final.ccacheStdenv;
          soapysdr = final.soapysdr-with-plugins;
        };
      };
      bird = inputs'.linyinfeng.packages.bird-babel-rtt;
      tailscale-derp = final.tailscale.overrideAttrs (old: {
        subPackages = old.subPackages ++ ["cmd/derper"];
      });
    })
  ];
  earlyFixes = final: prev: let
    inherit (prev.stdenv.hostPlatform) system;
    inherit ((getSystem system).allModuleArgs) inputs';
  in {
    # currently nothing
  };

  lateFixes = final: prev: let
    inherit (prev.stdenv.hostPlatform) system;
    inherit ((getSystem system).allModuleArgs) inputs';
    latest = import inputs.latest {
      inherit system;
      inherit (config.nixpkgs) config;
    };
  in {
    # TODO wait for https://nixpk.gs/pr-tracker.html?pr=257562
    inherit (latest) qq;

    # TODO broken
    fwupd =
      (prev.fwupd.override {
        stdenv = final.ccacheStdenv;
      })
      .overrideAttrs (old: {
        patches =
          (old.patches or [])
          ++ [
            ../patches/fwupd-lockdown-unknown-as-invalid.patch
          ];
      });
  };
in {
  nixpkgs = {
    config = {
      allowUnfree = true;
    };
    overlays = [earlyFixes] ++ packages ++ [lateFixes];
  };
}
