{ options, ... }:
{
  programs.nix-ld = {
    enable = true;
    libraries = options.programs.nix-ld.libraries.default ++ [ ];
  };
}
