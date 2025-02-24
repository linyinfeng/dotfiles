{ pkgs, ... }:
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
    profiles.default = {
      extensions = with pkgs.vscode-extensions; [ ];
    };
  };

  home.global-persistence.directories = [
    ".vscode"

    ".config/Code"
  ];
}
