# Commit Rules

- A commit subject is one line: no body, no bullet list.
- Your commits are authored `Nano <nano@linyinfeng.com>` and the human's stay their own:
  the pi wrapper exports `GIT_AUTHOR_*`/`GIT_COMMITTER_*`, so a plain `git commit` in a
  tool call already does it. Pass `-c user.name=Nano -c user.email=nano@linyinfeng.com`
  when that env is missing (an older session, or a shell the wrapper did not start).
