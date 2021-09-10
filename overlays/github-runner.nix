# TODO: https://github.com/NixOS/nixpkgs/issues/120263
channels: final: prev:
{
  github-runner = channels.latest.github-runner;
}
