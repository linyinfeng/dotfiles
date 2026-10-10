{
  config,
  self,
  lib,
  ...
}:
let
  # hydra's path /job/project/jobset/jobName contains job name
  getJobName = lib.replaceStrings [ "/" ] [ "-" ];
in
{
  options.hydraSystems = lib.mkOption {
    type = with lib.types; listOf str;
  };

  config.flake.hydraJobs = lib.mapAttrs' (name: lib.nameValuePair (getJobName name)) (
    self.lib.transposeAttrs (
      lib.filterAttrs (system: _: lib.elem system config.hydraSystems) self.checks
    )
  );
}
