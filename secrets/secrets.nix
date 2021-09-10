let
  t460p = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILlzCwC0yEkICPP/S5eSr41Kenl35n0N2ne2O+ZQ+j6y";
  xps8930 = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILRWO0HmTkgNBLLyvK3DodO4va2H54gHeRjhj5wSuxBq";
  x200s = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFb0b3IBA+0vYl32R4azIeofIDmff7jkBDk3Wg/7u293";
  portal = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIErlwC2p24gqh55P+nbtYXDB+Ya6airZOjQ0yLhlA1op";
  systems = [
    t460p
    xps8930
    x200s
    portal
  ];
  yinfeng = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIE9ZXqc9C4fS5gdUOaVdF4pVmStlCYFlHmOKUM/DKPxu";
  users = [
    yinfeng
  ];
  allKeys = systems ++ users;
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
  "transmission-credentials.age".publicKeys = allKeys;
  "cloudflare-token.age".publicKeys = allKeys;
  "yinfeng-nix-access-tokens.age".publicKeys = allKeys;
  "github-runner-xps8930.age".publicKeys = allKeys;
}
