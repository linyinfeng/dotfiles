#!/usr/bin/env bash

set -e

if [ -a /etc/INITIALIZED ]; then
  echo "already initialized"
  exit 0
fi

echo "start initialization"

CONFIG_NAME="${config_name}"

echo "install host private key"
cat > /etc/ssh/ssh_host_ed25519_key <<EOF
${host_ed25519_key}
EOF
chmod 600 /etc/ssh/ssh_host_ed25519_key
echo "install host public key"
cat > /etc/ssh/ssh_host_ed25519_key.pub <<EOF
${host_ed25519_key_pub}
EOF
chmod 644 /etc/ssh/ssh_host_ed25519_key.pub

echo "setup unstable channel"
nix-channel --add https://nixos.org/channels/nixos-unstable nixos
nix-channel --update

echo "get tools needed"
export PATH=$(nix-build '<nixpkgs>' -A nixVersions.unstable)/bin:$PATH
export PATH=$(nix-build '<nixpkgs>' -A util-linux)/bin:$PATH

echo "setup swap file"
fallocate -l 4G /swapfile
chmod 600 /swapfile
mkswap /swapfile
swapon /swapfile

echo "get latest configuration"
nix build --profile /nix/var/nix/profiles/system \
  "github:linyinfeng/dotfiles/tested#nixosConfigurations.$CONFIG_NAME.config.system.build.toplevel" \
  --verbose \
  --option extra-experimental-features "nix-command flakes" \
  --option extra-substituters "https://linyinfeng.cachix.org" \
  --option extra-trusted-public-keys "linyinfeng.cachix.org-1:sPYQXcNrnCf7Vr7T0YmjXz5dMZ7aOKG3EqLja0xr9MM="

echo "switch to new configuration"
/nix/var/nix/profiles/system/bin/switch-to-configuration boot

touch /etc/INITIALIZED

reboot
