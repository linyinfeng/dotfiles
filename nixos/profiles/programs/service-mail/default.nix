{
  config,
  pkgs,
  lib,
  ...
}:
let
  domain = "li7g.com";
  serviceMail = pkgs.writeShellScriptBin "service-mail" ''
    set -e

    account="$1"
    recipient="$2"
    subject="$3"
    ${pkgs.openssl}/bin/openssl s_client \
      -quiet -ign_eof \
      -starttls smtp -crlf \
      -connect smtp.ts.li7g.com:${toString config.ports.smtp-starttls} <<EOF
    HELO ${domain}
    AUTH LOGIN
    $(echo -n "$account" | base64)
    $(cat "${config.sops.secrets."mail_password".path}" | base64)
    MAIL FROM: <$account>
    RCPT TO: <$recipient>
    DATA
    From: <$account>
    To: <$recipient>
    Subject: $3

    $(cat)
    .
    QUIT
    EOF
  '';
in
{
  options = {
    programs.service-mail.package = lib.mkOption {
      type = lib.types.package;
      default = serviceMail;
    };
  };
  config = {
    environment.systemPackages = [ config.programs.service-mail.package ];
    sops.secrets."mail_password" = {
      terraformOutput.enable = true;
      mode = "440";
      group = config.users.groups.service-mail.name;
    };
    users.groups.service-mail.gid = config.ids.gids.service-mail;
  };
}
