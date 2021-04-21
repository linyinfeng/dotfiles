{ inputs }: with inputs;
{
  modules = [
    home.nixosModules.home-manager
    ci-agent.nixosModules.agent-profile

    # extra modules
    impermanence.nixosModules.impermanence
  ];

  overlays = [
    nur.overlay
    devshell.overlay
    (final: prev: {
      deploy-rs = deploy.packages.${prev.system}.deploy-rs;
    })
    pkgs.overlay

    # extra overlay
    emacs-overlay.overlay
  ];

  # passed to all nixos modules
  specialArgs = {
    overrideModulesPath = "${override}/nixos/modules";
    hardware = nixos-hardware.nixosModules;
  };

  # added to home-manager
  userModules = [

    # extra user modules
    (builtins.toPath "${impermanence}/home-manager.nix")
  ];

  # passed to all home-manager modules
  userSpecialArgs = { };
}
