{ ... }:

{
  perSystem =
    { config, ... }:
    {
      flatFlake.check.enable = config.isDevSystem;
    };
}
