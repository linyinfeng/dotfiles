# Code search and reading

- Identifier known, file unknown → `extensions.symbol_search`; file known, shape
  wanted → `extensions.module_report`; one symbol's body →
  `extensions.read_symbol`; the symbol around a line →
  `extensions.read_enclosing`; whole repo → `extensions.project_report`. This
  funnel is cheaper than reading files to find out what they contain; `pi.read`
  is the fallback when nothing narrower fits.
- `extensions.module_report`/`extensions.project_report` read the review graph:
  when it is cold or unavailable, `extensions.ast_grep_outline` gives
  syntax-only structure with no index.
- Exact string or regex → `pi.grep`. Structure matters (call shapes, imports,
  decorators) → `extensions.ast_grep_search`; AST inspection is that same ref
  with `dump=true`.
- One precise edit → `pi.edit`; the same structural rewrite repeated across files
  → `extensions.ast_grep_replace`.
- Who references this symbol, or rename it across files →
  `extensions.lsp_navigation`; when no language server covers the file, fall back
  to `pi.grep`.
