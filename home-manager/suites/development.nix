{ lib, ... }:
{
  world.profiles.git.enable = lib.mkDefault true;
  world.profiles.llm.general.enable = lib.mkDefault true;
  world.profiles.llm.pi.enable = lib.mkDefault true;
  world.profiles.llm.omp.enable = lib.mkDefault true;
  world.profiles.development.enable = lib.mkDefault true;
  world.profiles.emacs.enable = lib.mkDefault true;
  world.profiles.helix.enable = lib.mkDefault true;
  world.profiles.ssh.enable = lib.mkDefault true;
  world.profiles.pssh.enable = lib.mkDefault true;
  world.profiles.tools.enable = lib.mkDefault true;
  world.profiles.tex.enable = lib.mkDefault true;
  world.profiles.awscli.enable = lib.mkDefault true;
  world.profiles.terraform.enable = lib.mkDefault true;
  world.profiles.shells.enable = lib.mkDefault true;
  world.profiles.ok.enable = lib.mkDefault true;
  world.profiles.vscode-server.enable = lib.mkDefault true;
  world.profiles.terminal-multiplexing.enable = lib.mkDefault true;
  world.profiles.obsidian.enable = lib.mkDefault true;
}
