# TODO wait for https://github.com/NixOS/nixpkgs/issues/199318
# taken from https://github.com/NixOS/nixpkgs/blob/master/pkgs/servers/minio/default.nix
{ sources, lib, buildGoModule, fetchFromGitHub }:

let
  # The web client verifies, that the server version is a valid datetime string:
  # https://github.com/minio/minio/blob/3a0e7347cad25c60b2e51ff3194588b34d9e424c/browser/app/js/web.js#L51-L53
  #
  # Example:
  #   versionToTimestamp "2021-04-22T15-44-28Z"
  #   => "2021-04-22T15:44:28Z"
  versionToTimestamp = version:
    let
      splitTS = builtins.elemAt (builtins.split "(.*)(T.*)" version) 1;
    in
    builtins.concatStringsSep "" [ (builtins.elemAt splitTS 0) (builtins.replaceStrings [ "-" ] [ ":" ] (builtins.elemAt splitTS 1)) ];
in
buildGoModule rec {
  inherit (sources.minio) pname src;
  version = builtins.elemAt (builtins.elemAt (builtins.split "RELEASE\\.(.*)" sources.minio.version) 1) 0;
  vendorSha256 = "sha256-ccrCPI6vzc8B5KoxdERY/XcmwEDsNyWBMLZ0fELM7HM=";

  doCheck = false;

  subPackages = [ "." ];

  CGO_ENABLED = 0;

  tags = [ "kqueue" ];

  ldflags = let t = "github.com/minio/minio/cmd"; in [
    "-s"
    "-w"
    "-X ${t}.Version=${versionToTimestamp version}"
    "-X ${t}.ReleaseTag=RELEASE.${version}"
    "-X ${t}.CommitID=${src.rev}"
  ];
}
