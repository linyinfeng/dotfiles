{ pkgs, ... }:

{
  security.tpm2 = {
    enable = true;
    abrmd.enable = true;
    pkcs11.enable = true;
  };

  environment.systemPackages = with pkgs; [
    tpm2-tools
  ];
}
