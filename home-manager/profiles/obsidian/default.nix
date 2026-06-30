{ ... }:
{
  programs.obsidian = {
    enable = true;
    cli.enable = true;
    vaults = {
      knowledge-base.target = "Projects/knowledge-base";
    };
  };
}
