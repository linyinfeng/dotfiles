# Diagnostics and the done-check

- One file's type errors → `extensions.lens_diagnostics` with `source=lsp`; do
  not also run `tsc`/`cargo check` through `pi.bash`. When no language server
  covers the file, `pi.bash` is the only option — and say so.
- Before declaring work done → `extensions.lens_diagnostics` `mode=all` (a cache
  read). It also covers the non-LSP rules the LSP source misses.
- `mode=full` is a project-wide sweep plus a fresh analyzer run: not a per-file
  check, and not a substitute for a build or a test.
