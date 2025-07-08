{
  config,
  lib,
  pkgs,
  ...
}:
lib.mkMerge [
  {
    networking.networkmanager = {
      enable = true;
      logLevel = "INFO";
      connectionConfig = {
        "connection.mdns" = 2;
      };
      wifi.backend = "iwd";
      plugins = with pkgs; [
        networkmanager-strongswan
      ];
    };

    environment.global-persistence.directories = [ "/etc/NetworkManager/system-connections" ];
  }
  (lib.mkIf config.system.is-vm { networking.networkmanager.enable = lib.mkForce false; })

  # no search domain on public interfaces
  {
    networking.networkmanager.dispatcherScripts = [
      {
        type = "basic";
        source =
          let
            noSearchDomain = pkgs.writeShellApplication {
              name = "no-search-domain";
              runtimeInputs = with pkgs; [ networkmanager ];
              text = ''
                interface="$1"
                action="$2"
                if [ "$action" = "reapply" ] || [ "$action" = "down" ]; then
                  exit 0
                fi

                echo "script: no-search-domain"
                IFS=" " read -r -a search_domains_v4 <<< "''${DHCP4_DOMAIN_NAME:-}"
                IFS=" " read -r -a search_domains_v6 <<< "''${DHCP6_DOMAIN_LIST:-}"
                echo "interface=$interface; action=$action; search domains v4: ''${search_domains_v4[*]}; search domains v6: ''${search_domains_v6[*]}"
                routing_domains_v4=("''${search_domains_v4[@]/#/\~}")
                routing_domains_v6=("''${search_domains_v6[@]/#/\~}")
                if [ "''${#routing_domains_v4[@]}" -ne 0 ]; then
                  nmcli device modify "$interface" ipv4.dns-search "''${routing_domains_v4[*]}"
                fi
                if [ "''${#routing_domains_v6[@]}" -ne 0 ]; then
                  nmcli device modify "$interface" ipv6.dns-search "''${routing_domains_v6[*]}"
                fi
              '';
            };
          in
          "${noSearchDomain}/bin/no-search-domain";
      }
    ];
  }
]
