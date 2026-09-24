{ inputs, modulesPath, ... }:
{
  # nixpkgs ships an angrr module; the flake input tracks angrr upstream and replaces it
  disabledModules = [ "${modulesPath}/services/misc/angrr.nix" ];
  imports = [ inputs.angrr.nixosModules.angrr ];
}
