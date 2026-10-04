# Worktree Rules

Work happens in a git worktree, never on the target branch. The target-branch
checkout stays clean and is where `git worktree add/remove/move` and
`git branch -m` run; commit and push inside the worktree.

`git worktree add -b <topic> ~/Projects/worktrees/<PROJECT>/<topic>` — branch
`<topic>` off the latest target branch (`main`/`master`/`develop`), one topic per
worktree. Rename with `git worktree move <old> <new> && git branch -m <old>
<new>`; the branch name mirrors the directory name, so rename both together.
