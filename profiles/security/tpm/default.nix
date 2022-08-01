{ pkgs, ... }:

{
  security.tpm2 = {
    enable = true;
    abrmd.enable = true;
    # TODO broken https://github.com/NixOS/nixpkgs/pull/183798
    # pkcs11.enable = true;
  };

  environment.systemPackages = with pkgs; [
    tpm2-tools
  ];
}
