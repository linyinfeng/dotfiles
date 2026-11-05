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

Generate a reusable USB installation image:

```sh
maintain incusos image --arch x86_64-linux
maintain incusos image --arch aarch64-linux --output /path/to/incusos.img
```

This uses the packaged upstream flasher from `nur-packages` to download and
verify the stable image, then embed the selected public Incus client CA.
The default output is `.data/incusos/incusos-<arch>.img`. Existing outputs are
never overwritten. The seed uses DHCP/SLAAC and installs only to an unused disk;
it contains no private keys or machine-specific settings. Writing the image to
a USB device is a separate operation.

Generate only the architecture-independent seed, without downloading an image:

```sh
maintain incusos seed
maintain incusos seed --output /path/to/seed.tar
```

The default output is `.data/incusos/seed.tar`, suitable for `flasher-tool --seed`.
This uses the same seed generation as `image` and refuses existing output files.

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
