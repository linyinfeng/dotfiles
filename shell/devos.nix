{ pkgs, extraModulesPath, inputs, ... }:
let

  hooks = import ./hooks;

  pkgWithCategory = category: package: { inherit package category; };
  linter = pkgWithCategory "linter";
  docs = pkgWithCategory "docs";
  devos = pkgWithCategory "devos";
  secret = pkgWithCategory "secret";

in
{
  _file = toString ./.;

  imports = [ "${extraModulesPath}/git/hooks.nix" ];
  git = { inherit hooks; };

  commands = with pkgs; [
    (devos nixVersions.unstable)
    (devos cachix)
    {
      category = "devos";
      name = pkgs.nvfetcher-bin.pname;
      help = pkgs.nvfetcher-bin.meta.description;
      command = "cd $PRJ_ROOT/pkgs; ${pkgs.nvfetcher-bin}/bin/nvfetcher -c ./sources.toml $@";
    }
    (linter nixpkgs-fmt)
    (linter editorconfig-checker)
    (docs python3Packages.grip)
    (docs mdbook)
    (devos inputs.deploy.packages.${pkgs.system}.deploy-rs)

    (secret sops)
    (secret ssh-to-age)
  ];
}
