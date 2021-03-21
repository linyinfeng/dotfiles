{ pkgs, lib, ... }:

{
  programs.vscode = {
    enable = true;
    extensions = with pkgs.vscode-extensions; [
      ms-vscode.cpptools
    ];
  };

  home.activation.patchVSCodeServer = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    mkdir -p "$HOME/.vscode-server"
    ${pkgs.findutils}/bin/find "$HOME/.vscode-server" -maxdepth 3 -name node -exec $DRY_RUN_CMD ln -sf $VERBOSE_ARG ${pkgs.nodejs}/bin/node {} \;
  '';
}
