{ lib, ... }:
{
  networking.hostName = lib.mkForce "duo";
  networking.firewall.enable = lib.mkForce true;
  networking.defaultGateway.interface = "usb0";
  nix.enable = lib.mkForce true;
  users.users.root.initialPassword = lib.mkForce null;

  boot.kernelPatches = [
    {
      name = "extra-config";
      patch = null;
      extraConfig = ''
        TCG_TIS_CORE=m
        TCG_TIS=m
        TCG_TIS_SPI=m
        TCG_TIS_SPI_CR50=y
        TCG_TIS_I2C=m
        TCG_TIS_I2C_CR50=m
        TCG_TIS_I2C_ATMEL=m
        TCG_TIS_I2C_INFINEON=m
        TCG_TIS_I2C_NUVOTON=m
        TCG_TIS_ST33ZP24=m
        TCG_TIS_ST33ZP24_I2C=m
        TCG_TIS_ST33ZP24_SPI=m
      '';
    }
  ];
}
