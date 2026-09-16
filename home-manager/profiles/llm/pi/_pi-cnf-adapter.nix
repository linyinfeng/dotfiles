{
  pkgs,
  ...
}:
{
  programs.pi-command-not-found-adapter = {
    enable = true;
    model = "deepseek/deepseek-flash";
    # the machine is NixOS, so replace the generic prompt with the nix one
    systemPromptFile = [ pkgs.pi-command-not-found-adapter.passthru.prompts.nix ];
  };

  # the adapter's pi sessions and the notes they keep
  home.global-persistence.directories = [
    ".local/state/pi-command-not-found-adapter"
  ];
}
