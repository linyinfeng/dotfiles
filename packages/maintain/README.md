# Terraform state synchronization

## Incus automation identity

The existing root signs a dedicated `incus-v1` intermediate in the manual CA
stages. Incus 7.6 or newer is required for CA entries in the trust store.
Incus servers trust that intermediate for management clients; mesh and
services certificates do not grant Incus administration rights. Every client
signed by this intermediate inherits the CA trust entry's permissions, so only
Incus management identities may be issued by it.

The `pre-nixos` stage owns Terraform's ECDSA P-384 client key and issues a
90-day certificate, renewed 30 days before expiry. The private key remains in
encrypted stage state and outputs; public outputs include the client certificate
and its chain. Installation images embed the Incus intermediate certificate from
`intermediate_ca_certificates`, allowing client renewal without regenerating them.

The client key has destruction protection. Rotating the intermediate requires
updating server trust stores and installation images before retiring the old CA.

Generate a USB installation image for a hostname:

```sh
maintain incusos image --hostname ostrich --arch x86_64-linux
maintain incusos image --hostname ostrich --arch aarch64-linux --output /path/to/incusos.img
```

This uses the packaged upstream flasher from `nur-packages` to download and
verify the stable image, then embed a seed generated at runtime.
The default output is `.data/incusos/incusos-<hostname>-<arch>-<version>.img`,
using the actual downloaded IncusOS release version from the upstream image
filename. For example, `incusos-ostrich-x86_64-linux-202611112343.img`.
Existing outputs are never overwritten. The seed uses DHCP/SLAAC and by default
installs only to an unused disk;
it includes the requested hostname and no private keys. Writing the image to
a USB device is a separate operation.

Images also merge the public Secure Boot certificates in
[`packages/incusos-secureboot`](../incusos-secureboot/README.md) into their
enrollment databases. Shared Microsoft certificates and certificates for the
requested hostname are added to upstream IncusOS trust; host revocations are
retained. The upstream PK is unchanged. Initial enrollment requires Setup Mode.

Both `seed` and `image` accept `--force-install/--no-force-install` (default:
`--no-force-install`). This sets `install.json`'s `force_install`: enabling it
allows the IncusOS installer to erase existing partitions on its target disk.
It does not erase a disk while generating files and does not change flash's USB
write behavior. For example:

```sh
maintain incusos seed --hostname ostrich --force-install --output /path/to/seed.tar
maintain incusos image --hostname ostrich --arch x86_64-linux --force-install
```

Seed configuration lives in `packages/incusos-seed/*.json`. It is not a Nix
package: maintain reads these files from the checkout at runtime and inserts
the selected public Incus CA from `lib/data/data.json`. Both commands validate
the CA before use. Configuration and CA changes do not require rebuilding maintain.
Both generation commands require `--hostname` and write it to `network.json` as
`dns.hostname`, preserving any other network settings. Use a single hostname
label of 1-63 ASCII letters, digits or hyphens, with no leading or trailing
hyphen. Flash uses the hostname already embedded in the supplied image or seed.

The initial Tailscale configuration is enabled, uses a random UDP port, accepts
tailnet DNS, and has no accepted or advertised routes, exit node advertisement,
or Tailscale Serve. Both commands use SOPS at runtime to decrypt only
`tailscale_tailnet_key.value` from the encrypted pre-nixos Terraform outputs
(respecting `SECRETS_DIR`) and insert it as `services.json`'s `tailscale.auth_key`.
The key stays in memory until written into the seed; decryption failure aborts
generation before downloading an image. SOPS decryption credentials are required.

Generate only the architecture-independent seed, without downloading an image:

```sh
maintain incusos seed --hostname ostrich
maintain incusos seed --hostname ostrich --output /path/to/seed.tar
```

The default output is `.data/incusos/seed.tar`, suitable for `flasher-tool --seed`.
It uses the same runtime generator as `image` and refuses existing output files.
Generated seeds and images are written with mode 0600 so they can be managed as
secrets. Keep credentials out of tracked configuration files and Nix builds;
credential injection happens at runtime. The resulting seed and image contain
the plaintext authentication key and must be handled as secrets. Existing
images are not updated; generate a new image to include Tailscale authentication.

Flash the complete image to a USB disk, or update only its existing seed partition:

```sh
maintain incusos flash /dev/disk/by-id/usb-... --image /path/to/incusos.img
maintain incusos flash /dev/disk/by-id/usb-... --seed /path/to/seed.tar
```

Use exactly one of `--image` or `--seed`, specifying the file explicitly.

Always pass the whole USB disk, including for `--seed`: maintain locates the
`seed-data` partition itself. The image mode erases the disk's partition layout;
the seed mode writes only that partition. Both modes refuse non-USB disks,
partition targets, read-only devices, mounted filesystems, active swap or block
mappings, and insufficient capacity. Unmount the USB filesystems first.
The command displays the disk model, serial number and destination, asks for
confirmation (`--yes` skips it), and verifies the written bytes by reading them
back. Non-root invocations automatically re-execute flash through the host's
`run0` before opening the device or source file. Paths are expanded
before elevation; device checks, confirmation, writing and verification run in
one privileged session. Root invocations run directly. It does not generate a
new seed or image.

## Commands

The package includes Bash and Fish completions generated with
`maintain completion bash` and `maintain completion fish`. The
devshell exposes them through `XDG_DATA_DIRS`; the Fish shell profile refreshes
its completion search path when direnv changes that variable.

`maintain terraform bootstrap`, `apply-stage`, `pipe`, `pipe-all`, `run`, and
`update-outputs` share the same Git synchronization around their work:

1. Acquire a local lock in the secrets repository's Git directory.
2. Refuse uncommitted state/output changes for the selected stages.
3. Pull the secrets repository with `--ff-only`.
4. Execute the operation, re-encrypt state, and remove plaintext state.
5. Commit only changed state/output files for those stages and push.

`pipe-all` synchronizes once around all routine stages. Use
`pipe-all --include-manual` to run `intermediate-ca`, `root-ca`, `pre-nixos`, and
`post-nixos` in that order. This option remains local-only; CI rejects it before
executing any stage. States must already be bootstrapped.
`pipe` and `pipe-all` also format dotfiles after publishing state.
`pipe-all` extracts Terraform host secrets once after all selected stages succeed,
before publishing state and formatting. A single pre-nixos apply still extracts
its Terraform host secrets immediately after refreshing its outputs and data.
Ordinary `init` does not synchronize state; backend migration flags are refused.

Update provider locks for every registered stage, or just one:

```sh
maintain terraform update-locks
maintain terraform update-locks root-ca
```

This uses `init -backend=false -upgrade` in temporary copies containing only
Terraform configuration, then copies back only the provider lock files.
It runs in CI for manual stages too, without accessing their state or secrets.

A failed or interrupted Terraform operation can still change state. Its encrypted
state is committed and pushed before the original failure is returned. Later
stages do not run after a failure. Outputs are refreshed only if apply succeeds.

If publishing fails, encrypted files and local commits remain available for
recovery. Retry `git push` for an existing commit. To commit and push pending
Terraform state/output files after checking them, use:

```sh
maintain terraform commit-outputs 'Recover Terraform state'
```

This recovery command includes registered stages' state/output files, including
manual stages, and leaves unrelated staged files out of its commit. Leftover
plaintext state requires manual recovery before another Terraform operation.

Git synchronization and the local lock do not provide a distributed state lock.
Avoid running the same stage concurrently on different machines or in CI.
