{
  config,
  pkgs,
  lib,
  ...
}:
let
  sbCfg = config.boot.secureBoot;
  cfg = sbCfg.shim;
  inherit (config.boot.loader.efi) efiSysMountPoint;
  installShim = pkgs.writeShellApplication {
    name = "install-shim";
    runtimeInputs = with pkgs; [
      efibootmgr
      gawk
      coreutils
      glibc
      singEfiFile
    ];
    text =
      ''
        esp_device=$(df --portability "${efiSysMountPoint}" | awk 'END{print $1}')
        if [[ $esp_device =~ ^(.+)p([0-9]+)$ ]]; then
          disk="''${BASH_REMATCH[1]}"
          part="''${BASH_REMATCH[2]}"
        else
          echo "unable to parse ESP device path $esp_device" >&2
          exit 1
        fi

        for file in shim mm; do
          target="${efiSysMountPoint}/${cfg.directory}/''${file}${cfg.archSuffix}.efi"
          echo "installing $target..."
          cp "${cfg.package}/share/shim/''${file}${cfg.archSuffix}.efi" "$target"
          echo "signing $target..."
          sign-efi-file "$target"
        done

        # https://github.com/rhboot/shim/blob/main/README.fallback
        boot_csv_file="${efiSysMountPoint}/${cfg.directory}/BOOT.CSV"
        echo "creating $boot_csv_file..."
        iconv --to-code=UCS-2 --output="$boot_csv_file" <<EOF
        shim${cfg.archSuffix}.efi,${cfg.fallback.label},${cfg.fallback.loaderData},${lib.concatStringsSep "," cfg.fallback.comments}
        EOF
      ''
      + lib.optionalString cfg.removable.enable ''
        for file in shim mm fb; do
          target="${efiSysMountPoint}/EFI/BOOT/''${file}${cfg.archSuffix}.efi"
          echo "installing $target..."
          cp "${cfg.package}/share/shim/''${file}${cfg.archSuffix}.efi" "$target"
          echo "signing $target..."
          sign-efi-file "$target"
        done
        mv --verbose \
           "${efiSysMountPoint}/EFI/BOOT/shim${cfg.archSuffix}.efi" \
           "${efiSysMountPoint}/EFI/BOOT/BOOT${lib.toUpper cfg.archSuffix}.efi"
      ''
      + lib.optionalString cfg.bootEntry.install ''
        echo "cleaning boot entry..."
        efibootmgr --quiet --delete-bootnum --label "${cfg.bootEntry.label}" || true
        echo "creating boot entry..."
        efibootmgr --quiet --create --label "${cfg.bootEntry.label}" \
          --disk "$disk" --part "$part" --loader '\${
            lib.replaceStrings [ "/" ] [ "\\" ] cfg.directory
          }\shim${cfg.archSuffix}.efi'
      ''
      + lib.optionalString cfg.mokManager.addEntry ''
        echo "creating MokManager boot entry..."
        mkdir --parents "${efiSysMountPoint}/loader/entries"
        cat >"${efiSysMountPoint}/loader/entries/mok-manager.conf" <<EOF
        title MokManager
        version ${cfg.package.version}
        sort-key mokmanager
        efi /${cfg.directory}/mm${cfg.archSuffix}.efi
        EOF
      '';
  };
  singEfiFile = pkgs.writeShellApplication {
    name = "sign-efi-file";
    runtimeInputs = with pkgs; [ sbsigntool ];
    text = ''
      file="$1"
      tmpfile=$(mktemp -t "sign-efi-file.XXXXXXXX")
      sbsign --cert "${config.boot.secureBoot.publicKeyFile}" \
             --key "${config.boot.secureBoot.privateKeyFile}" \
             "$file" --output "$tmpfile" 2>/dev/null
      cp "$tmpfile" "$file"
    '';
  };
in
{
  options = {
    boot.secureBoot.shim = {
      enable = lib.mkEnableOption "shim";
      loader = lib.mkOption {
        type = lib.types.str;
        apply = lib.replaceStrings [ "\\" ] [ "\\\\" ];
      };
      package = lib.mkOption {
        type = lib.types.package;
        default = pkgs.shim-unsigned.override { defaultLoader = cfg.loader; };
      };
      archSuffix = lib.mkOption {
        type = lib.types.str;
        readOnly = true;
        default = cfg.package.archSuffix;
      };
      directory = lib.mkOption {
        type = lib.types.str;
        description = ''
          Directory relative to the root of ESP.
        '';
      };
      fallback = {
        label = lib.mkOption {
          type = lib.types.str;
          default = cfg.bootEntry.label;
        };
        loaderData = lib.mkOption {
          type = lib.types.str;
          default = "";
        };
        comments = lib.mkOption {
          type = with lib.types; listOf str;
          default = [ "This is the boot entry for ${cfg.fallback.label}" ];
        };
      };
      removable.enable = lib.mkEnableOption "removable";
      bootEntry = {
        install = lib.mkEnableOption "EFI boot entry";
        label = lib.mkOption { type = lib.types.str; };
      };
      mokManager = {
        addEntry = lib.mkEnableOption "MokManager boot entry";
      };
    };
  };
  config = lib.mkIf cfg.enable {
    system.build = {
      inherit installShim;
    };
    environment.systemPackages = with pkgs; [ mokutil ];
  };
}
