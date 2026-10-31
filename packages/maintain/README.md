# Terraform state synchronization

`maintain terraform bootstrap`, `apply-stage`, `pipe`, `pipe-all`, `run`, and
`update-outputs` share the same Git synchronization around their work:

1. Acquire a local lock in the secrets repository's Git directory.
2. Refuse uncommitted state/output changes for the selected stages.
3. Pull the secrets repository with `--ff-only`.
4. Execute the operation, re-encrypt state, and remove plaintext state.
5. Commit only changed state/output files for those stages and push.

`pipe-all` synchronizes once around all routine stages. Manual stages such as
`root-ca` are excluded. `pipe` also formats dotfiles after publishing state.
Ordinary `init` does not synchronize state; backend migration flags are refused.

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
