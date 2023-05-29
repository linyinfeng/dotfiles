{...}: {
  imports = [../devshell];
  perSystem = {self', system, lib, ...}: {
    checks = lib.mapAttrs' (name: drv: lib.nameValuePair  "devShells/${name}" drv) self'.devShells;
  };
}
