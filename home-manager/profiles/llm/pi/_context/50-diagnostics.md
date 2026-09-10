# Diagnostics and the done-check

- One file's type errors → `lsp_diagnostics`; do not also run `tsc`/`cargo check`
  through `bash`. When no language server covers the file, `bash` is the only
  option — and say so.
- Before declaring work done → `lens_diagnostics mode=all` (a cache read). It
  also covers the non-LSP rules `lsp_diagnostics` misses.
- `mode=full` is a project-wide sweep plus a fresh analyzer run: not a per-file
  check, and not a substitute for a build or a test.
