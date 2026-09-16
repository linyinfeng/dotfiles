# Delegation routing

Pick the surface by what the work needs, not by which tool is closest to hand:

- A shell command that outlives the turn → `bg_run`, and anything you can wait
  for is `bash`.
- Read-only investigation that needs this conversation as context →
  `bg_delegate`.
- A role, edits, model tiering, or several children → `subagent`.
- A command that needs a TTY, or an interactive CLI (`vim`, `psql`, `ssh`, a
  REPL) → `interactive_shell`.
- Root → `sudo_run`, never `interactive_shell`, even though the password prompt
  looks interactive: privileged approval happens outside the overlay, so an
  overlay waiting on the prompt only stalls.
- Several model perspectives on one prompt → `fusion_*`.

None of these exists to run an ordinary non-interactive command — that is
`bash`, or `bg_run` once it outlives the turn — and none is worth it for what
two or three direct tool calls finish: read the file, run the command, answer.

- `interactive_shell` modes: `interactive` and `hands-free` keep running and are
  queried with `sessionId`; `dispatch` and `monitor` return immediately and wake
  the session on completion or on a monitor trigger; `background: true` runs one
  headless. `/spawn`, `/attach` and `/dismiss` are the user-facing entries,
  structured `spawn` is the agent-side one, and raw `command` covers any other
  CLI.

- `bg_delegate` vs `subagent` (`scout`): both read the repo — `bg_delegate` when
  the child needs this conversation as context, `subagent` when it needs a role,
  a model tier, or is one lane of a workflow.
- `bg_result` retrieves a `bg_delegate`/`fusion_*` answer; a `subagent` run is
  inspected and steered through `subagent`'s own actions.
- Fusion by input: `fusion_reason` (reasoning only), `fusion_investigate` (a
  repo), `fusion_research` (the URLs you name), `fusion_validate` (review of
  finished work).
- One notification is the terminal truth: never sleep or poll `bg_*` to wait.
  `bg_wait` is for provider or detached work that has no notification of its
  own.
- Background output under `.pi/tasks` is durable; the task registry is not —
  task ids do not survive a parent restart.
- A child that asks through `contact_supervisor` is answered with
  `subagent_supervisor` — reply to it, do not preempt it.
