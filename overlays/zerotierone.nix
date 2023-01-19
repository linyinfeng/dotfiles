# TODO report or fix the package
final: prev:
{
  zerotierone =
    if final.stdenv.hostPlatform.system == "aarch64-linux" then
      prev.zerotierone.overrideAttrs
        (old: {
          meta = old.meta // {
            broken = true;
          };
        }) else prev.zerotierone;
}
