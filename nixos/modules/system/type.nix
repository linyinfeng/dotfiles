{lib, ...}: {
  options.system.types = lib.mkOption {
    type = with lib.types;
      listOf (enum [
        "server"
        "workstation"
        "phone"
      ]);
    default = [];
    description = ''
      system types.
    '';
  };
}
