# Offline root CA

This manual Terraform stage uses `hashicorp/tls` to create an ECDSA P-384 X.509
root, self-signed with SHA-384 and valid for 3,650 days (approximately 10 years).
It permits one intermediate CA level. There is no early renewal;
`prevent_destroy` protects both the private key and certificate against replacement.
The provider proposes renewal once the certificate expires; renewal remains a
manual operation because this stage never runs in CI or routine pipelines.

GPG protects the root private key in `infrastructure-secrets/terraform/states/root-ca.tfstate`.
Only the personal PGP recipients in `devshell/sops-yaml.nix` can decrypt this
state; the GitHub Actions age identity is excluded. GPG is not the X.509 signing
key. Applying this stage decrypts the root state locally, so use a trusted machine.
Public certificate and expiry outputs are saved to
`terraform/outputs/root-ca.yaml`, encrypted for personal PGP keys and the CI age
identity; no private-key output is exported. The pre-nixos stage reads this file
and publishes `root_ca_cert_pem` as a non-sensitive output, making it available
through `lib/data/data.json`. No separate certificate export is needed.

Run once from dotfiles with the GPG/YubiKey identity available:

```sh
nix develop --command maintain terraform bootstrap intermediate-ca
nix develop --command maintain terraform pipe intermediate-ca
nix develop --command maintain terraform bootstrap root-ca
nix develop --command maintain terraform pipe root-ca
```

`bootstrap` refuses existing state. Later runs use `pipe` without bootstrap.
Both commands pull the secrets repository before execution and commit/push changed
state afterwards. Commit any existing local root state/output changes first.
The stage is excluded from `pipe-all` unless `--include-manual` is passed, and
refuses to run under `CI` or `GITHUB_ACTIONS`.
It does not alter the existing pre-nixos CA, host certificates,
Secure Boot keys, or system trust stores.

Run the root stage successfully before applying pre-nixos: bootstrap alone only
creates empty state and does not produce the public outputs file.

Intermediate keys and enrollment requests are provisioned by the separate,
manual `intermediate-ca` stage. Its state and outputs are encrypted for personal
PGP keys and CI age; its private keys are for online leaf signing only.
Provision `intermediate-ca` before applying `root-ca`. Review the configured
CSRs and the Terraform plan, then confirm the local root apply to sign them.
There is no separate approval file or pinned CSR digest. Only the intermediate
names configured in `intermediates.tf` are signed. Intermediates receive
five-year certificates with a maximum path length of zero. Root outputs contain
only public certificates and metadata.

Keep independent, recoverable backups of the encrypted state and personal GPG keys.
