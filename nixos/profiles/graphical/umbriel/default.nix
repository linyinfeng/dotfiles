{
  inputs,
  ...
}:
{
  imports = [ inputs.umbriel.nixosModules.default ];

  programs.umbriel.enable = true;
}
