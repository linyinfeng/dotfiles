{pkgs, ...}: {
  home.packages = with pkgs; [
    hledger
    hledger-ui
  ];
  home.sessionVariables = {
    "LEDGER_FILE" = "$HOME/Syncthing/Main/ledger/main.journal";
  };
}
