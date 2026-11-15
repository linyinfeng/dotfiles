# IncusOS Secure Boot certificates

`maintain incusos image --hostname HOST ...` adds these public certificates to
the upstream image's automatic enrollment databases before publishing the image:

- Microsoft certificates are read directly from NUR's
  `linyinfeng.sources.secureboot_objects.src/PreSignedObjects/{KEK,DB}/Certificates`
  through the packaged `MAINTAIN_SECUREBOOT_MICROSOFT` path. They are not copied
  into this repository.
- `hosts/HOST/{KEK,db}/*.pem`: certificates specific to that motherboard.
- `hosts/HOST/dbx.esl`: the motherboard's exported revocation list.

The initial files were exported from ostrich's GIGABYTE B650I AX rev.1.0 after
restoring F41e on 2026-11-15. PEM filenames are SHA-256 certificate fingerprints.
All seven exported Microsoft certificates match the NUR source byte-for-byte
in DER form; the host directory contains only GIGABYTE entries.
The original export is backed up separately under `.data/incusos/`.

The output keeps all upstream IncusOS certificates and adds the configured
certificates, deduplicating by signature type and certificate/hash bytes. The
upstream and host dbx revocations are combined. The upstream IncusOS PK and
signed boot/system images are unchanged. No private keys are stored here.

The merged KEK/db/dbx enrollment files use unsigned AUTH2 descriptors, which
UEFI accepts only in **Setup Mode**. systemd-boot registers these databases
before enrolling the upstream PK and rebooting. These files cannot authorize
updates on a system already in User Mode. They are replacement databases
containing the merged entries, not append updates. Export any additional
machine-specific keys before using a newly configured host: certificates absent
from the configured files cannot be preserved automatically.

References: [IncusOS security](https://linuxcontainers.org/incus-os/docs/main/reference/security/),
[UEFI authenticated variables](https://uefi.org/specs/UEFI/2.10/08_Services_Runtime_Services.html).
