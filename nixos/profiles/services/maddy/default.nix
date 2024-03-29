{
  config,
  pkgs,
  lib,
  ...
}:
{
  options = {
    services.maddy-init.accounts = lib.mkOption {
      type = with lib.types; listOf str;
      default = [ ];
    };
  };
  config = {
    services.maddy = {
      enable = true;
      hostname = "smtp.li7g.com";
      primaryDomain = "li7g.com";
      localDomains = [ "$(primary_domain)" ];
      openFirewall = false;
      tls = {
        loader = "file";
        certificates = with config.security.acme.tfCerts."li7g_com"; [
          {
            certPath = fullChain;
            keyPath = key;
          }
        ];
      };
      config = ''
        # Local storage & authentication

        auth.pass_table local_authdb {
          table sql_table {
            driver postgres
            dsn "host=/var/run/postgresql dbname=maddy user=maddy sslmode=disable"
            table_name passwords
          }
        }

        # SMTP endpoints + message routing

        # hostname already set by nixos configuration

        table.chain local_rewrites {
          optional_step regexp "(.+)\+(.+)@(.+)" "$1@$3"
          optional_step static {
            entry postmaster postmaster@$(primary_domain)
          }
        }

        submission tls://0.0.0.0:${toString config.ports.smtp-tls} tcp://0.0.0.0:${toString config.ports.smtp-starttls} {
          limits {
            # Up to 50 msgs/sec across any amount of SMTP connections.
            all rate 50 1s
          }

          auth &local_authdb

          source $(local_domains) {
            check {
              authorize_sender {
                prepare_email &local_rewrites
                user_to_email identity
              }
            }

            default_destination {
              modify {
                modify.dkim {
                  domains $(primary_domain) $(local_domains)
                  selector default
                  key_path {env:CREDENTIALS_DIRECTORY}/dkim.key
                }
              }
              deliver_to &remote_queue
            }
          }
          default_source {
            reject 501 5.1.8 "Non-local sender domain"
          }
        }

        target.remote outbound_delivery {
          limits {
            # Up to 20 msgs/sec across max. 10 SMTP connections
            # for each recipient domain.
            destination rate 20 1s
            destination concurrency 10
          }
          mx_auth {
            dane
            mtasts {
              cache fs
              fs_dir mtasts_cache/
            }
            local_policy {
              min_tls_level encrypted
              min_mx_level none
            }
          }
        }

        target.queue remote_queue {
          target &outbound_delivery

          autogenerated_msg_domain $(primary_domain)
          bounce {
            default_destination {
              reject 550 5.0.0 "Refusing to send DSNs to non-local addresses"
            }
          }
        }
      '';
    };
    sops.secrets."dkim_private_pem" = {
      terraformOutput.enable = true;
      restartUnits = [ "maddy.service" ];
    };
    systemd.services.maddy.serviceConfig.LoadCredential = [
      "dkim.key:${config.sops.secrets."dkim_private_pem".path}"
    ];
    services.postgresql.ensureDatabases = [ "maddy" ];
    services.postgresql.ensureUsers = [
      {
        name = "maddy";
        ensureDBOwnership = true;
      }
    ];
    users.users.maddy.extraGroups = [ config.users.groups.acmetf.name ];
    # allow su to maddy to use maddyctl
    users.users.maddy.shell = pkgs.bash;
    systemd.services.maddy = {
      requires = [
        "postgresql.service"
        "maddy-init.service"
      ];
      after = [ "postgresql.service" ];
    };

    # accounts
    services.maddy-init.accounts = [
      "hydra@li7g.com"
      "vault@li7g.com"
      "smartd@li7g.com"
      "grafana@li7g.com"
      "alertmanager@li7g.com"
      "matrix@li7g.com"
      "mastodon@li7g.com"
      "keycloak@li7g.com"
      "nextcloud@li7g.com"
    ];
    sops.secrets."mail_password" = {
      terraformOutput.enable = true;
      restartUnits = [ "maddy-init.service" ];
    };
    systemd.services.maddy-init = {
      after = [ "maddy.service" ];
      serviceConfig = {
        User = "maddy";
        Type = "oneshot";
        RemainAfterExit = true;
        LoadCredential = [ "password:${config.sops.secrets."mail_password".path}" ];
      };
      path = [ pkgs.maddy ];
      script = ''
        PASSWORD_FILE="$CREDENTIALS_DIRECTORY/password"
        function add_user {
          USER="$1"
          if [[ $(maddyctl creds list)  == *"$1"* ]]; then
            echo "user '$USER' already exists, updating password..."
            cat "$PASSWORD_FILE" | maddyctl creds password "$USER"
            echo "password of '$USER' changed"
          else
            cat "$PASSWORD_FILE" | maddyctl creds create "$USER"
            echo "user '$USER' added"
          fi
        }

        ${lib.concatStringsSep "\n" (
          builtins.map (a: "add_user \"${a}\"") config.services.maddy-init.accounts
        )}
      '';
    };

    networking.firewall.allowedTCPPorts = with config.ports; [
      smtp-tls
      smtp-starttls
    ];
  };
}
