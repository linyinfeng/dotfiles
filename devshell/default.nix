{...}: {
  imports = [
    ./terraform
  ];
  perSystem = {
    inputs',
    pkgs,
    ...
  }: {
    devshells.default = {
      commands = [
        {
          package = inputs'.nixos-generators.packages.nixos-generate;
          category = "deploy";
        }
        {
          package = pkgs.sops;
          category = "secrets";
        }
        {
          package = pkgs.ssh-to-age;
          category = "secrets";
        }
      ];
    };
  };
}
