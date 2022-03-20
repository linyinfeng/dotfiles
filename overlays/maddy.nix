final: prev:
let
  withTagLibpam = prev.maddy.override {
    buildGoModule = args: final.buildGoModule (args // {
      tags = [ "libpam" ];
    });
  };
in
{
  maddy = withTagLibpam.overrideAttrs (old: {
    buildInputs = (old.buildInputs or [ ]) ++ [
      final.pam
    ];
  });
}
