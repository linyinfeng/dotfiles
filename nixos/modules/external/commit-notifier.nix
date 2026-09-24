{ inputs, ... }:
{
  imports = [ inputs.commit-notifier.nixosModules.commit-notifier ];
}
