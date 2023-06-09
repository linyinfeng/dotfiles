{lib, ...}: let
  prefix = "2001:470:1d:4ff";
  suffixes = [
    "5f77:ca0b:c7ea:04ae"
    "811b:b277:8d7c:7a4e"
    "1613:7472:6315:d569"
    "1f44:0cf6:181e:e7f8"
    "986d:78a6:5c25:cf29"
    "73b5:c312:1fec:70f0"
    "acee:5fb8:f089:733b"
    "521d:5067:a9f8:8bfe"
    "b4db:5e05:5bc0:b873"
    "8185:563f:da1f:e27e"
    "d6f6:6e23:b9e0:9ab8"
    "0406:cd4d:7658:c122"
    "591e:f664:801f:8965"
    "0aef:3e5c:7503:e18e"
    "8a51:08a2:386c:cfa7"
    "38fb:39a0:e751:b85d"
    "982d:8fd1:eded:25f9"
    "2429:5a59:8afc:fefd"
    "7fc1:56c1:a565:13d3"
    "2045:f576:91ed:8cc1"
    "db1c:9de8:b42c:9d00"
    "92e6:4928:cea9:c7f2"
    "4c00:f8fb:9ce1:6944"
    "1ba6:7650:34a5:e8e4"
    "f927:52c6:075c:21bb"
    "49bf:2aab:bcbb:9c76"
    "e481:0835:ecd4:2784"
    "9404:9e0b:7f4e:bbd7"
    "0192:f62c:bdcc:193e"
    "70b1:868c:f7a4:37a8"
    "63be:c0cb:58a4:a405"
    "00a7:0abf:a494:22c5"
    "752a:cbcd:0085:ee5f"
    "f29b:3232:4533:02e7"
    "454a:3175:a1b8:1191"
    "3086:4a2b:0ccb:c78d"
    "39ac:2c20:c1b6:a4e5"
    "72f5:839a:28e5:ea02"
    "d0f9:3624:f006:6bc5"
    "1a41:c4e7:5e88:8a18"
    "965b:abee:b5c2:8d90"
    "8311:f0c3:a188:ac84"
    "3c0a:0e7a:f3ea:a321"
    "7e44:1d52:f269:629a"
    "fdd3:84bc:101d:55aa"
    "1112:3724:4b4e:d97d"
    "397a:64bb:1c53:0566"
    "a61c:41c0:94f6:3a65"
    "9fa2:78f0:25f3:84b7"
    "edf6:a4e7:70ec:a806"
    # "1889:0291:4b0b:aded"
    # "dd6f:f4eb:f4b9:bbff"
    # "7474:cac1:8f1a:e02a"
    # "da28:042b:5da0:b7f6"
    # "72ec:7cca:2e31:2a92"
    # "9d77:9eb4:bf5d:4cec"
    # "8ba0:9ed7:4e51:ad28"
    # "f00d:e16f:98c6:aea7"
    # "8797:d35e:ab8c:4eae"
    # "a79b:a2a8:90b6:71a0"
    # "8f7c:6513:2655:2c4a"
    # "619b:89c9:3e08:777b"
    # "bf74:381c:d129:a659"
    # "36eb:d370:6993:bfe7"
    # "edbb:0b7e:ede8:65d1"
    # "2910:5cb9:b50e:eb23"
    # "ccb6:b44c:2d52:804b"
    # "8b79:8b8c:832d:b910"
    # "916b:7f55:8fd7:9dd4"
    # "b0a3:ccd5:2d0a:0f68"
    # "fa01:a127:968e:7767"
    # "fcd7:350b:bb14:426d"
    # "d823:85d7:e2f9:5098"
    # "e8dc:a00c:4818:41ab"
    # "8b32:7c85:fc50:ad43"
    # "70eb:f98f:9338:14f1"
    # "4deb:1a38:c2de:a7bd"
    # "0b08:0cc8:d4bd:050e"
    # "7d35:5ede:719e:fd86"
    # "fd03:3d66:0115:5602"
    # "e6cf:83ce:274b:c246"
    # "d074:6af4:ec97:1fb1"
    # "8d9e:9082:e800:364e"
    # "f9ad:8fef:ea8e:d413"
    # "820e:5288:a160:7c3d"
    # "cc1a:f39b:55ac:cb69"
    # "ed39:a8d7:6863:9e7b"
    # "8e12:b21f:53be:abbd"
    # "a3ef:a03d:0625:c720"
    # "726b:abd9:b791:3ef1"
    # "9a94:fe52:823b:6310"
    # "3035:7d90:3759:12c7"
    # "cb96:0a61:1cae:69a1"
    # "9027:e163:3227:a736"
    # "a966:309c:884a:bbe3"
    # "8ab7:ee6b:e7d7:307b"
    # "5d81:1f4e:1148:f2a3"
    # "a472:0634:c874:401d"
    # "8e2a:360e:a2d4:a608"
    # "0683:4b49:3b51:4d8f"
  ];
  mkContainerName = suffix: "reddit-grab-${lib.replaceStrings [":"] ["-"] suffix}";
  mkContainer = suffix:
    lib.nameValuePair (mkContainerName suffix) {
      autoStart = true;
      image = "atdr.meo.ws/archiveteam/reddit-grab";
      cmd = ["--concurrent" "1" "linyinfeng" "--disable-web-server" "--context-value" "bind_address=${prefix}:${suffix}"];
      extraOptions = [
        "--network=host"
        "--label"
        "io.containers.autoupdate=registry"
      ];
    };
in {
  virtualisation.oci-containers.containers = lib.listToAttrs (lib.lists.map mkContainer suffixes);
  boot.kernel.sysctl = {
    "net.ipv6.ip_nonlocal_bind" = 1;
  };
  systemd.timers.podman-auto-update = {
    timerConfig.OnCalendar = "*:0/10"; # every 10 minutes
    wantedBy = ["timers.target"];
  };
  systemd.network.networks."50-he-ipv6" = {
    matchConfig = {
      Name = "he-ipv6";
    };
    routes = [
      {
        routeConfig = {
          Type = "local";
          Destination = "${prefix}::/64";
        };
      }
    ];
  };
}
