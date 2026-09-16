# Delegation routing

Pick the surface by what the work needs, not by which ref is closest to hand:

- A shell command that outlives the turn → `extensions.bg_run`, and anything you
  can wait for is `pi.bash`.
- Read-only investigation that needs this conversation as context →
  `extensions.bg_delegate`.
- A role, edits, model tiering, or several children → `extensions.subagent`.
- A command that needs a TTY, or an interactive CLI (`vim`, `psql`, `ssh`, a
  REPL) → `extensions.interactive_shell`.
- Several model perspectives on one prompt → `extensions.fusion_*`.
- A privileged command → `pi.bash` running `run0` (or `pkexec`), which
  authenticates through your session's polkit agent. Each authentication costs
  you a password prompt, so batch all root work into one call instead of issuing
  several. `sudo` here is `run0-sudo-shim`, which execs `run0`: `sudo -n` always
  fails, and a piped `sudo -S` password cannot work.

None of these exists to run an ordinary non-interactive command — that is
`pi.bash`, or `extensions.bg_run` once it outlives the turn — and none is worth
it for what two or three direct refs finish: read the file, run the command,
answer.

- `extensions.interactive_shell` modes: `interactive` and `hands-free` keep
  running and are queried with `sessionId`; `dispatch` and `monitor` return
  immediately and wake the session on completion or on a monitor trigger;
  `background: true` runs one headless. `/spawn`, `/attach` and `/dismiss` are the
  user-facing entries, structured `spawn` is the agent-side one, and raw
  `command` covers any other CLI.
- `extensions.bg_delegate` vs `extensions.subagent`: both read the repo —
  `bg_delegate` when the child needs this conversation as context, `subagent`
  when it needs a role, a model tier, or is one lane of a workflow.
- `extensions.bg_result` retrieves a `bg_delegate`/`fusion_*` answer; a
  `subagent` run is inspected and steered through `extensions.subagent`'s own
  actions.
- Fusion by input: `extensions.fusion_reason` (reasoning only),
  `extensions.fusion_investigate` (a repo), `extensions.fusion_research` (the URLs
  you name), `extensions.fusion_validate` (review of finished work).
- One notification is the terminal truth: never sleep or poll `bg_*` to wait.
  `extensions.bg_wait` is for provider or detached work that has no notification
  of its own.
- Background output under `.pi/tasks` is durable; the task registry is not —
  task ids do not survive a parent restart.
- A child that asks through `contact_supervisor` is answered with
  `extensions.subagent_supervisor` — reply to it, do not preempt it.
