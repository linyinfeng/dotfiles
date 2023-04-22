{pkgs, ...}: {
  home.packages = with pkgs; [
    hledger
    hledger-ui
  ];
  home.sessionVariables = {
    "LEDGER_FILE" = "$HOME/Sources/hledger-journal/main.journal";
  };
}
