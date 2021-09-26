{ pkgs, config, ... }:

{
  programs.telegram-send = {
    enable = true;
    configFile = config.age.secrets.push-bot.path;
  };

  age.secrets.push-bot = {
    file = config.age.secrets-directory + /push-bot.age;
    mode = "440";
    group = config.users.groups.wheel.name;
  };
}
