{
  lib,
  pkgs,
  python3Packages,
  makeWrapper,
  age,
  coreutils,
  git,
  nix,
  openssh,
  prettier,
  sops,
  yq-go,
  terraform,
  zerotierone,
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
    intermediate-ca = { };
    root-ca = {
      "intermediate_ca_outputs_path" = "\${SECRETS_DIR}/terraform/outputs/intermediate-ca.yaml";
    };
    pre-nixos = {
      "root_ca_outputs_path" = "\${SECRETS_DIR}/terraform/outputs/root-ca.yaml";
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
  manualStages = [
    "intermediate-ca"
    "root-ca"
  ];
  # eval fails if this list and the registry disagree
  stageOrder =
    assert
      builtins.sort builtins.lessThan (stageOrderList ++ manualStages)
      == builtins.sort builtins.lessThan (builtins.attrNames stages);
    stageOrderList;

  stageRegistry = pkgs.writeText "terraform-stages.json" (
    builtins.toJSON {
      order = stageOrder;
      manual = manualStages;
      inherit stages;
    }
  );
  sopsConfig = (pkgs.formats.yaml { }).generate "maintain-sops.yaml" (
    import ../../devshell/sops-yaml.nix { inherit lib; }
  );

  # tools the pipelines shell out to, next to terraform itself
  runtimeTools = [
    age
    bind
    coreutils
    git
    openssh
    efitools
    git
    jq
    libargon2
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
  nativeCheckInputs = [
    python3Packages.pytestCheckHook
    git
  ];

  postInstall = ''
    install -Dm644 ${stageRegistry} $out/share/maintain/terraform-stages.json
  '';

  postFixup = ''
    wrapProgram $out/bin/maintain \
      --prefix PATH : ${lib.makeBinPath runtimeTools} \
      --set MAINTAIN_STAGE_REGISTRY ${stageRegistry} \
      --set MAINTAIN_SOPS_CONFIG ${sopsConfig}
  '';

  meta = {
    description = "maintenance CLI for this repository";
    mainProgram = "maintain";
  };
}
