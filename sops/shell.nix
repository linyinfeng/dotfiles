{ flk ? import ./..
, system ? builtins.currentSystem
}:
let
  pkgs = flk.pkgs.${system}.nixos;
in
pkgs.mkShell {
  sopsPGPKeyDirs = [
    "./keys/hosts"
    "./keys/users"
  ];
  nativeBuildInputs = with pkgs; [
    sops-pgp-hook
    ssh-to-pgp
  ];
}
