{ pkgs, ... }:
{
  home.packages = with pkgs; [
    hledger
    hledger-ui
  ];
  home.sessionVariables = {
    "LEDGER_FILE" = "$HOME/Projects/hledger-journal/main.journal";
  };
}
