{ lib }:
let
  inherit (lib) dev;

  profiles = dev.os.mkProfileAttrs (toString ../profiles);
  userProfiles = dev.os.mkProfileAttrs (toString ../users/profiles);
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
    campus = with networking; [ campus-network ];

    workstation = base ++ multimedia ++ development ++ virtualization ++ network ++ wireless ++ (with services; [ openssh printing ]);
    campusWorkstation = workstation ++ campus;
    mobileWorkstation = campusWorkstation ++ [ laptop ];
  };

  # available as 'suites' within the home-manager configuration
  userSuites = with userProfiles; rec {
    base = [ direnv git shells ];
    multimedia = [ gnome desktop-applications rime ];
    development = [ emacs latex tools ];
    multimediaDev = multimedia ++ development ++ [ ides vscode ];
    synchronize = [ onedrive digital-paper ];
    gfw = [ proxychains ];

    full = base ++ multimediaDev ++ synchronize ++ gfw;
  };

in
{
  system = lib.mapAttrs (_: v: dev.os.profileMap v) suites // {
    inherit allProfiles allUsers;
  };
  user = lib.mapAttrs (_: v: dev.os.profileMap v) userSuites // {
    allProfiles = userProfiles;
  };
}
