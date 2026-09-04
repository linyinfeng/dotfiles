# Worktree Rules

Work (features, fixes, experiments) happens in a git worktree, never on the
target branch.

- Worktrees live at `~/Projects/worktrees/<PROJECT>/<TOPIC>`, branch `<TOPIC>`
  off the latest target branch (the branch it merges back to, e.g.
  `main`/`master`/`develop`). One topic = one worktree.
- The target-branch checkout stays clean; it is the admin repo — `git
  worktree` add/remove/move and `git branch -m` run there. Work, commit, push
  inside the worktree.
- Create: `git worktree add -b <topic> ~/Projects/worktrees/<PROJECT>/<topic>`.
- Rename in place: `git worktree move <old> <new> && git branch -m <old> <new>`
  — branch name mirrors the worktree dir name; rename both together.