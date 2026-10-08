# Commit Rules

- A commit subject is one line: no body, no bullet list.
- Your commits are authored `Nano <nano@linyinfeng.com>` and carry the human as
  `Co-authored-by: Lin Yinfeng <lin.yinfeng@outlook.com>`: the pi wrapper exports
  `GIT_AUTHOR_*`/`GIT_COMMITTER_*` and puts a `git` shim first on `PATH` that adds the
  trailer, so a plain `git commit` does both. The human's own commits stay their own.
- When that env is missing (an older session, or a shell the wrapper did not start),
  pass `-c user.name=Nano -c user.email=nano@linyinfeng.com` and
  `--trailer 'Co-authored-by: Lin Yinfeng <lin.yinfeng@outlook.com>'` yourself.
