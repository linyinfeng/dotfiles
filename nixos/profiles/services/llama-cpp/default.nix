{
  config,
  lib,
  pkgs,
  ...
}:
let
  stateDir = "/var/lib/llama-cpp";

  # Command-line arguments outrank both preset sections, so anything a model may
  # want to override has to live in the preset file instead of `settings`.
  defaults = {
    parallel = 1;
    flash-attn = "on";
    cache-type-k = "q8_0";
    cache-type-v = "q8_0";
    batch-size = 2048;
    ubatch-size = 512;
    # the prompt cache competes with the experts of a CPU-offloaded MoE model
    cache-ram = 2048;
  };

  # Section names must equal the GGUF file names: the router otherwise lists the
  # discovered file and the preset as two models, and only the preset carries the
  # per-model options. The scanner ignores anything not ending in `.gguf`, which is
  # how retired checkpoints stay in the models directory without being served.
  presets = {
    # the MTP checkpoint is 12% larger and decodes slower without speculation, so
    # the speculation has to stay with it; n-max 2 measured fastest (50.8 vs 44.2 t/s)
    "Qwen3.5-9B-MTP-UD-Q4_K_XL" = {
      spec-type = "draft-mtp";
      spec-draft-n-max = 2;
      load-on-startup = false;
    };
    "Qwen3.6-35B-A3B-MTP-UD-Q4_K_XL" = {
      n-cpu-moe = 32;
      spec-type = "draft-mtp";
      spec-draft-n-max = 2;
      load-on-startup = false;
    };
  };

  modelsPreset = (pkgs.formats.ini { }).generate "llama-cpp-models.ini" (
    # the router reads the shared defaults from the `[*]` section
    { "*" = defaults; } // presets
  );
in
{
  services.llama-cpp = {
    enable = true;
    # a host may narrow the compiled CUDA architectures
    package = lib.mkDefault pkgs.llama-cpp-cuda;
    settings = {
      port = config.ports.llama-cpp;
      # the key is passed as a systemd credential, which the DynamicUser can read
      api-key-file = "/run/credentials/llama-cpp.service/api-key";
      # the default (4) lets two models fight over 8 GB of VRAM
      models-max = 1;
      # one directory for both hand-placed GGUFs and Hugging Face downloads, so
      # that the persistent `/var/lib` makes both survive a reboot
      models-dir = stateDir;
      models-preset = modelsPreset;
    };
  };

  systemd.services.llama-cpp = {
    # Hugging Face downloads go through the network proxy
    environment = lib.mkIf config.networking.fw-proxy.enable config.networking.fw-proxy.environment;
    serviceConfig.LoadCredential = [ "api-key:${config.sops.secrets."llama_cpp_api_key".path}" ];
  };

  sops.secrets."llama_cpp_api_key" = {
    terraformOutput.enable = true;
    restartUnits = [ "llama-cpp.service" ];
  };

  services.nginx.virtualHosts."llama-cpp.*" = {
    forceSSL = true;
    inherit (config.security.acme.tfCerts."li7g_com".nginxSettings) sslCertificate sslCertificateKey;
    locations."/" = {
      proxyPass = "http://127.0.0.1:${toString config.ports.llama-cpp}";
      extraConfig = ''
        proxy_buffering off;
        proxy_cache off;
        proxy_read_timeout 1h;
      '';
    };
  };
}
