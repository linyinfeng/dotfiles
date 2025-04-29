{ config, self, ... }:
let
  helper = config.lib.topology;
in
{
  nodes = {
    internet = helper.mkInternet {
      connections = helper.mkConnection "home-router" "pppoe-out1";
    };
    home-ont = helper.mkRouter "Home ONT" {
      info = "ONT";
      interfaceGroups = [
        [
          "wan"
          "lan"
        ] # bridged
      ];
      interfaces.lan.network = "home-ont";
    };
    home-router = helper.mkRouter "Home Router" {
      info = "MikroTik hEX S";
      interfaceGroups = [
        [ "ether1" ]
        [ "pppoe-out1" ]
        [
          "ether2"
          "ether3"
          "ether4"
          "ether5"
        ]
        [ "wireguard1" ]
      ];
      connections.ether1 = helper.mkConnection "home-ont" "lan";
      interfaces = {
        wireguard1.network = "home-vpn";
        ether2.network = "home";
        ether3.network = "home";
        ether4.network = "home";
        ether5.network = "home";
      };
    };
    home-room-router = helper.mkRouter "Home Room Router" {
      info = "Mi Router 4A";
      interfaceGroups = [
        [
          "lan1"
          "lan2"
        ]
        [ "wan" ]
      ];
      connections.wan = helper.mkConnection "home-router" "ether3";
      connections.lan1 = helper.mkConnection "home-room-switch" "lan1";
    };
    home-room-switch = helper.mkSwitch "Home Room Switch" {
      info = "GETGEAR GS105E";
      interfaceGroups = [
        [
          "lan1"
          "lan2"
          "lan3"
          "lan4"
          "lan5"
        ]
      ];
      # connections.lan2 = helper.mkConnection "nuc" "enp88s0";
      connections.lan3 = helper.mkConnection "nuc-kvm" "lan";
    };
    nuc-kvm = helper.mkDevice "NUC KVM" {
      info = "Oray KVM A2";
      interfaceGroups = [ [ "lan" ] ];
    };
  };
  networks = {
    internet = {
      name = "Internet";
      cidrv4 = "0.0.0.0/0";
      cidrv6 = "::/0";
    };
    home-ont = {
      name = "Home (ONU)";
      cidrv4 = "192.168.1.1/24";
    };
    home = {
      name = "Home";
      cidrv4 = "192.168.0.1/24";
    };
    home-vpn = {
      name = "Home (VPN)";
      cidrv4 = "192.168.2.1/24";
    };
    dn42 = {
      name = "DN42";
      cidrv4 = self.lib.data.dn42_v4_cidr;
      cidrv6 = self.lib.data.dn42_v6_cidr;
    };
  };
}
