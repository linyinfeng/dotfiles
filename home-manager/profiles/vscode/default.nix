{ lib, pkgs, ... }:
{
  programs.vscode = {
    enable = true;
    # TODO wait for https://github.com/microsoft/vscode/issues/187338
    package = pkgs.vscode.overrideAttrs (old: {
      postInstall =
        (old.postInstall or "")
        + ''
          wrapProgram "$out/bin/code" \
            --add-flags --password-store=gnome-libsecret
        '';
    });
    extensions = with pkgs.vscode-extensions; [ ];
  };

  home.activation.patchVSCodeServer = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    mkdir -p "$HOME/.vscode-server"
    ${pkgs.findutils}/bin/find "$HOME/.vscode-server" -maxdepth 3 -name node -exec $DRY_RUN_CMD ln -sf $VERBOSE_ARG ${pkgs.nodejs}/bin/node {} \;
  '';

  home.global-persistence.directories = [
    ".vscode"
    ".vscode-server"

    ".config/Code"
  ];
}
