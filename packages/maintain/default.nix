{
  lib,
  python3Packages,
  makeWrapper,
  sops,
}:
python3Packages.buildPythonApplication {
  pname = "maintain";
  version = "0-unstable";

  pyproject = true;
  src = ./.;

  build-system = [ python3Packages.hatchling ];
  dependencies = [ python3Packages.typer ];

  nativeBuildInputs = [ makeWrapper ];
  nativeCheckInputs = [ python3Packages.pytestCheckHook ];

  postFixup = ''
    wrapProgram $out/bin/maintain --prefix PATH : ${lib.makeBinPath [ sops ]}
  '';

  meta = {
    description = "maintenance CLI for this repository";
    mainProgram = "maintain";
  };
}
