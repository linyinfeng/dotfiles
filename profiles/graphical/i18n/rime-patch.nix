# TODO wait for https://nixpk.gs/pr-tracker.html?pr=219315
{ inputs, ... }:
{
  disabledModules = [
    "i18n/input-method/fcitx5.nix"
    "i18n/input-method/ibus.nix"
  ];
  imports = [
    "${inputs.nixpkgs-ibus-rime-data}/nixos/modules/i18n/input-method/rime.nix"
    "${inputs.nixpkgs-ibus-rime-data}/nixos/modules/i18n/input-method/ibus.nix"
    "${inputs.nixpkgs-ibus-rime-data}/nixos/modules/i18n/input-method/fcitx5.nix"
  ];
}
