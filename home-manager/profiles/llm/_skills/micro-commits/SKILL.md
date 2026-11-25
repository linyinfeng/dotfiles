---
name: micro-commits
description: >-
  Work in tiny, verified Git commits (micro-commits).
  Activate ONLY when the user explicitly asks for micro-commits;
  never activate implicitly for ordinary coding, refactoring, or Git tasks.
---

# Micro-Commits

Develop incrementally through a sequence of minimal, self-contained, verified
commits:

- **Plan in tiny steps**: Break the change into minimal units that each leave
  the codebase working (e.g., extract a helper, rename a symbol, add one
  behavior with its test, wire one call site).
- **Commit as you go**: Execute `edit -> verify -> commit` for one step before
  starting edits for the next. Never make bulk edits first and split them into
  commits retroactively.
- **Separate structure from behavior**: Never mix structural changes (renaming,
  moving, extracting, formatting) with behavioral changes (features, fixes) in
  the same commit.
- **Keep every commit green**: Run fast, targeted checks (formatter, typecheck,
  or touched tests) before each commit so every revision is a valid rollback
  point; run broader checks at completion. Never commit broken code, debug
  leftovers, or `WIP` checkpoints—if a step goes wrong, `git restore` back to
  the last green commit and retry smaller.
- **Stage and describe precisely**: Inspect `git diff`, stage explicit paths
  rather than blind `git add -A`, and write concise subjects matching repo and
  environment commit conventions. Keep the micro-commit sequence intact unless
  the user asks to squash or rebase.
