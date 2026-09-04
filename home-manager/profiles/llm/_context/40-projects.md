# Project Repos

All source repos live in `~/Projects`. When you need to inspect a remote
repo's content:

1. First check whether it's already cloned locally (`~/Projects/<repo>`).
   If it exists, read it there — don't reach for the remote again.
2. If not, `git clone <url> ~/Projects/<repo>` and inspect the local tree.

Local clones beat scraping: local source search and full-context analysis
only work on files. Treat cloned repos as read-only unless the task is to
work on them.
