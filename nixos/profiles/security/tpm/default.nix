{pkgs, ...}: {
  security.tpm2 = {
    enable = true;
    # TODO broken on framework
    # abrmd.enable = true;
  };

  environment.systemPackages = with pkgs; [
    tpm2-tools
  ];
}
