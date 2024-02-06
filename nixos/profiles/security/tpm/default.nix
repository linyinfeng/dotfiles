{pkgs, ...}: {
  security.tpm2 = {
    enable = true;
    abrmd.enable = true;
  };

  environment.systemPackages = with pkgs; [
    tpm2-tools
  ];
}
