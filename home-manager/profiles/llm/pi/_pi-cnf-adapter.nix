{
  ...
}:
{
  programs.pi-command-not-found-adapter = {
    enable = true;
    model = "deepseek/deepseek-flash";
  };

  # the adapter's pi sessions and the notes they keep
  home.global-persistence.directories = [
    ".local/state/pi-command-not-found-adapter"
  ];
}
