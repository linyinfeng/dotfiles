{ config, ... }:

{
  services.nginx.gitweb = {
    enable = true;
    group = config.users.groups.users.name;
  };
  services.gitweb.extraConfig = ''
    $site_name = 'Git';
    $project_maxdepth = 1;
  '';

  environment.global-persistence.directories = [
    config.services.gitweb.projectroot
  ];
}
