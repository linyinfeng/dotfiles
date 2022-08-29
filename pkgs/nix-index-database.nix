{ stdenvNoCC, sources }:

stdenvNoCC.mkDerivation {
  inherit (sources.nix-index-database) pname version src;
  unpackPhase = ''
    gzip --decompress $src --stdout > database
  '';
  installPhase = ''
    cp database $out
  '';
}
