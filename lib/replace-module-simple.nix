{ replaceModules }:
nixpkgs: module:
replaceModules {
  fromNixpkgs = nixpkgs;
  modules = [ module ];
}
