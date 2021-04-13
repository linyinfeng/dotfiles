{ lib, ... }:

{
  users.users.root.hashedPassword =
    lib.removeSuffix "\n" (builtins.readFile ../../secrets/users/root/hashedPassword.txt);
}
