{pkgs, ...}: {
  # canokey
  services.udev.packages = [
    pkgs.nur.repos.linyinfeng.canokey-udev-rules
  ];

  services.pcscd = {
    enable = true;
    plugins = with pkgs; [
      ccid
    ];
  };

  hardware.gpgSmartcards.enable = true;

  environment.systemPackages = with pkgs; [
    yubikey-manager
    pcsctools

    # TODO wait for https://nixpk.gs/pr-tracker.html?pr=281421
    pcscliteWithPolkit.out
  ];

  # disabled
  security.pam.u2f = {
    enable = false;
    cue = false;
  };
  environment.global-persistence.user.directories = [
    ".config/Yubico"
  ];
}
