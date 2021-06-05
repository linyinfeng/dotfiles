let
  yinfeng-t460p = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILlzCwC0yEkICPP/S5eSr41Kenl35n0N2ne2O+ZQ+j6y";
  yinfeng-work = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILRWO0HmTkgNBLLyvK3DodO4va2H54gHeRjhj5wSuxBq";
  yinfeng-x200s = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFb0b3IBA+0vYl32R4azIeofIDmff7jkBDk3Wg/7u293";
  portal = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIErlwC2p24gqh55P+nbtYXDB+Ya6airZOjQ0yLhlA1op";
  systems = [
    yinfeng-t460p
    yinfeng-work
    yinfeng-x200s
    portal
  ];
  user = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIE9ZXqc9C4fS5gdUOaVdF4pVmStlCYFlHmOKUM/DKPxu";
  allKeys = systems ++ [ user ];
in
{
  "clash-dler.age".publicKeys = allKeys;
  "clash-cnix.age".publicKeys = allKeys;
  "portal-client-id.age".publicKeys = allKeys;
  "user-root-password.age".publicKeys = allKeys;
  "user-yinfeng-password.age".publicKeys = allKeys;
  "campus-net-username.age".publicKeys = allKeys;
  "campus-net-password.age".publicKeys = allKeys;
  "yinfeng-asciinema-token.age".publicKeys = allKeys;
  "yinfeng-id-ed25519.age".publicKeys = allKeys;
}
