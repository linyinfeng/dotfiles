{
  lib,
  pkgs,
  python3Packages,
  makeWrapper,
  git,
  nix,
  prettier,
  sops,
  yq-go,
  terraform,
  zerotierone,
  minio-client,
  syncthing,
  libargon2,
  jq,
  openssl,
  ruby,
  efitools,
  bind,
  xray,
}:
let
  # TF_VAR_* declared per stage; the wrapper exports only these
  stages = {
    pre-nixos = {
      "terraform_input_path" = "\${SECRETS_DIR}/terraform-inputs.yaml";
      "predefined_secrets_path" = "\${SECRETS_DIR}/predefined.yaml";
    };
    post-nixos = {
      "terraform_input_path" = "\${SECRETS_DIR}/terraform-inputs.yaml";
      # stage interface: the previous stage's encrypted outputs
      "pre_nixos_outputs_path" = "\${SECRETS_DIR}/terraform/outputs/pre-nixos.yaml";
    };
  };
  stageOrderList = [
    "pre-nixos"
    "post-nixos"
  ];
  # eval fails if this list and the registry disagree
  stageOrder =
    assert
      builtins.sort builtins.lessThan stageOrderList
      == builtins.sort builtins.lessThan (builtins.attrNames stages);
    stageOrderList;

  stageRegistry = pkgs.writeText "terraform-stages.json" (
    builtins.toJSON {
      order = stageOrder;
      inherit stages;
    }
  );

  # tools the pipelines shell out to, next to terraform itself
  runtimeTools = [
    bind
    efitools
    git
    jq
    libargon2
    minio-client
    nix
    openssl
    prettier
    ruby
    sops
    syncthing
    terraform
    xray
    yq-go
    zerotierone
  ];
in
python3Packages.buildPythonApplication {
  pname = "maintain";
  version = "0-unstable";

  pyproject = true;
  src = ./.;

  build-system = [ python3Packages.hatchling ];
  dependencies = [ python3Packages.typer ];

  nativeBuildInputs = [ makeWrapper ];
  nativeCheckInputs = [ python3Packages.pytestCheckHook ];

  postInstall = ''
    install -Dm644 ${stageRegistry} $out/share/maintain/terraform-stages.json
  '';

  postFixup = ''
    wrapProgram $out/bin/maintain \
      --prefix PATH : ${lib.makeBinPath runtimeTools} \
      --set MAINTAIN_STAGE_REGISTRY ${stageRegistry}
  '';

  meta = {
    description = "maintenance CLI for this repository";
    mainProgram = "maintain";
  };
}
