{ lib, runCommand }:
runCommand "fish-direnv-completions"
  {
    meta = {
      description = "Refresh Fish completion search paths when direnv changes XDG_DATA_DIRS";
      platforms = lib.platforms.unix;
    };
  }
  ''
    install -Dm644 ${./direnv-completions.fish} \
      $out/share/fish/vendor_conf.d/direnv-completions.fish
  ''
