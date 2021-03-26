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

    network = (with networking; [ network-manager resolved ]) ++ (with security; [ fail2ban firewall ]);
    multimedia = (with graphical; [ gnome fonts ibus-chinese ]) ++ (with services; [ sound ]);
    development = (with profiles.development; [ shells latex ]) ++ (with services; [ adb gnupg ]);
    multimediaDev = multimedia ++ development ++ (with profiles.development; [ ides ]);
    virtualization = with profiles.virtualization; [ anbox docker libvirt wine ];
    wireless = with services; [ bluetooth ];
    gfw = with networking; [ gfw-proxy ];
    campus = with networking; [ campus-network ];
    game = with graphical.game; [ steam ];

    workstation = base ++ multimediaDev ++ virtualization ++ network ++ wireless ++ (with services; [ openssh printing ]);
    campusWorkstation = workstation ++ campus;
    mobileWorkstation = campusWorkstation ++ [ laptop ];
  };

  # available as 'suites' within the home-manager configuration
  userSuites = with userProfiles; rec {
    base = [ direnv git shells ];
    multimedia = [ gnome desktop-applications rime ];
    development = [ userProfiles.development emacs tools ];
    virtualization = [ ];
    multimediaDev = multimedia ++ development ++ [ vscode ];
    synchronize = [ onedrive digital-paper ];

    full = base ++ multimediaDev ++ virtualization ++ synchronize;
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
