{
  config,
  pkgs,
  lib,
  ...
}: let
  iperfExp = pkgs.writeText "iperf.exp" ''
    #!${lib.getExe pkgs.expect} -f

    set timeout -1
    spawn iperf3 \
      --rsa-public-key-path "${config.sops.secrets."iperf_public_key".path}" \
      --username [exec cat "${config.sops.secrets."iperf_username".path}"] \
      --port ${toString config.ports.iperf} \
      {*}$argv
    match_max 100000
    expect -exact "Password: "
    send -- "[exec cat "${config.sops.secrets."iperf_password".path}"]\r"
    expect eof
  '';
  iperfAuthed = pkgs.writeShellApplication {
    name = "iperf3-authed";
    runtimeInputs = with pkgs; [
      iperf3
      expect
    ];
    text = ''
      expect -f "${iperfExp}" -- "$@"
    '';
  };
in {
  services.iperf3 = {
    enable = true;
    port = config.ports.iperf;
    rsaPrivateKey = "/%d/private-key";
    authorizedUsersFile = "/%d/hashed-password";
  };
  systemd.services.iperf3 = {
    serviceConfig = {
      LoadCredential = [
        "private-key:${config.sops.secrets."iperf_private_key".path}"
        "hashed-password:${config.sops.secrets."iperf_hashed_password".path}"
      ];
    };
  };
  sops.secrets."iperf_private_key" = {
    terraformOutput.enable = true;
    restartUnits = ["iperf3.service"];
  };
  sops.secrets."iperf_hashed_password" = {
    terraformOutput.enable = true;
    restartUnits = ["iperf3.service"];
  };
  networking.firewall = {
    allowedTCPPorts = [
      config.ports.iperf
    ];
    allowedUDPPorts = [
      config.ports.iperf
    ];
  };

  environment.systemPackages = [
    iperfAuthed
  ];
  sops.secrets."iperf_public_key" = {
    terraformOutput.enable = true;
    restartUnits = [];
    group = "wheel";
    mode = "440";
  };
  sops.secrets."iperf_username" = {
    terraformOutput.enable = true;
    restartUnits = [];
    group = "wheel";
    mode = "440";
  };
  sops.secrets."iperf_password" = {
    terraformOutput.enable = true;
    restartUnits = [];
    group = "wheel";
    mode = "440";
  };
}
