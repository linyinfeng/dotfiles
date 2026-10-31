{
  config,
  self,
  lib,
  getSystem,
  ...
}:
let
  # hydra's path /job/project/jobset/jobName contains job name
  getJobName = lib.replaceStrings [ "/" ] [ "-" ];
  jobs = lib.mapAttrs' (name: lib.nameValuePair (getJobName name)) (
    self.lib.transposeAttrs (
      lib.filterAttrs (system: _: lib.elem system config.hydraSystems) self.checks
    )
  );
in
{
  options.hydraSystems = lib.mkOption {
    type = with lib.types; listOf str;
  };

  config.flake.hydraJobs = jobs // {
    # A stable status that succeeds only after every job, including cached builds.
    required = (getSystem "x86_64-linux").allModuleArgs.pkgs.releaseTools.aggregate {
      name = "dotfiles-required";
      constituents = lib.collect lib.isDerivation jobs;
    };
  };
}
