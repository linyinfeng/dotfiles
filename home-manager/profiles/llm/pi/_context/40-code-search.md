# Code search and reading

- Identifier known, file unknown → `symbol_search`; file known, shape wanted →
  `module_report`; one symbol's body → `read_symbol`; the symbol around a line →
  `read_enclosing`; whole repo → `project_report`. This funnel is cheaper than
  reading files to find out what they contain; `read` is the fallback when
  nothing narrower fits.
- `module_report`/`project_report` read the review graph: when it is cold or
  unavailable, `ast_grep_outline` gives syntax-only structure with no index.
- Exact string or regex → `bash` with `rg`. Structure matters (call shapes,
  imports, decorators) → `ast_grep_search`; when a pattern returns nothing and
  the node kind is unknown → `ast_grep_dump`.
- One precise edit → `edit`; the same structural rewrite repeated across files →
  `ast_grep_replace`.
- Who references this symbol, or rename it across files → `lsp_navigation`; when
  no language server covers the file, fall back to `rg`.
