{ lib }:
let
  inherit (lib) dev;

  profiles = dev.os.mkProfileAttrs (toString ../profiles);
  users = dev.os.mkProfileAttrs (toString ../users);

  allProfiles =
    let defaults = lib.collect (x: x ? default) profiles;
    in map (x: x.default) defaults;

  allUsers =
    let defaults = lib.collect (x: x ? default) users;
    in map (x: x.default) defaults;


  suites = with profiles; rec {
    base = [ basic users.root users.yinfeng ];

    network = with networking; [ network-manager resolved ];
    multimedia = (with graphical; [ gnome fonts ibus-chinese ]) ++ (with services; [ sound ]);
    development = (with profiles.development; [ shells ]) ++ (with services; [ adb ]);
    virtualization = with profiles.virtualization; [ anbox docker libvirt wine ];
    wireless = with services; [ bluetooth ];
    gfw = with networking; [ gfwProxy ];

    workstation = base ++ multimedia ++ development ++ virtualization ++ network ++ (with services; [ openssh printing ]);
    mobileWorkstation = workstation ++ wireless ++ [ laptop ];
  };
in
lib.mapAttrs (_: v: dev.os.profileMap v) suites // {
  inherit allProfiles allUsers;
}
