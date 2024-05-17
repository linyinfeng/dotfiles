{ self, lib, ... }:
let
  # hydra's path /job/project/jobset/jobName contains job name
  getJobName = lib.replaceStrings [ "/" ] [ "-" ];
in
{
  flake.hydraJobs = lib.mapAttrs' (name: lib.nameValuePair (getJobName name)) (
    self.lib.transposeAttrs self.checks
  );
}
