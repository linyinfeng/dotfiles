# TODO a workaround
# https://github.com/nix-community/nix-direnv/issues/109
# https://github.com/numtide/devshell/issues/149
final: prev: {
  nix-direnv =
    prev.nix-direnv.overrideAttrs
      (old: {
        patches = (old.patches or [ ]) ++ [
          ./nix-direnv-shell-hook.patch
        ];
      });
}
