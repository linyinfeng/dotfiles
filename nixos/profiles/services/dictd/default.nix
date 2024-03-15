{ pkgs, ... }:
{
  services.dictd = {
    enable = true;
    DBs = with pkgs.dictdDBs; [
      wiktionary
      wordnet
    ];
  };
}
