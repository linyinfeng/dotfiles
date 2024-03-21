{ self, ... }:

{
  flake.hydraJobs = self.lib.transposeAttrs self.checks;
}
