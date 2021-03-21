{ ... }:

{
  users.users.root.hashedPassword =
    import ../../secrets/users/root/hashedPassword.nix;
}
