{ pkgs, ... }:
{
  home.packages = with pkgs; [
    hledger
    hledger-ui
  ];
  home.sessionVariables = {
    "LEDGER_FILE" = "$HOME/Source/hledger-journal/main.journal";
  };
}
