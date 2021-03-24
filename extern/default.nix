{ inputs }: with inputs;
{
  modules = [
    home.nixosModules.home-manager
    ci-agent.nixosModules.agent-profile

    impermanence.nixosModules.impermanence
  ];

  overlays = [
    nur.overlay
    devshell.overlay
    (final: prev: {
      deploy-rs = deploy.packages.${prev.system}.deploy-rs;
    })
    pkgs.overlay

    emacs-overlay.overlay
    (final: prev: {
      nixops-flake = nixops.defaultPackage.${prev.system};
    })
  ];

  # passed to all nixos modules
  specialArgs = {
    overrideModulesPath = "${override}/nixos/modules";
    hardware = nixos-hardware.nixosModules;
  };

  # added to home-manager
  userModules = [
  ];

  # passed to all home-manager modules
  userSpecialArgs = { };
}
