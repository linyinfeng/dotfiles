{lib, ...}: {
  options.system.types = lib.mkOption {
    type = with lib.types;
      listOf (enum [
        "server"
        "workstation"
      ]);
    default = [];
    description = ''
      system types.
    '';
  };
}
