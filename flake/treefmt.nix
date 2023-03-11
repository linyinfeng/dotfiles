{...}: {
  perSystem = {...}: {
    treefmt = {
      projectRootFile = "flake.nix";
      programs = {
        alejandra.enable = true;
        shfmt.enable = true;
        terraform.enable = true;
      };
    };
  };
}
