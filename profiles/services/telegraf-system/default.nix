{ config, ... }:

{
  services.telegraf-influx = {
    enable = true;
    configUrl = "http://nuc.ts.li7g.com:3004/api/v2/telegrafs/089cd877a38d0000";
    tokenFile = config.sops.secrets."telegraf/influx-token".path;
  };
  sops.secrets."telegraf/influx-token" = {};
}
