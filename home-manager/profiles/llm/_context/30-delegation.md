# Delegation Routing

Pick the surface by what the work needs, not by which tool is closest to hand.

| The work needs                               | Use                         |
| -------------------------------------------- | --------------------------- |
| A shell command that outlives the turn       | `bg_run`                    |
| Read-only investigation needing this context | `bg_delegate` → `bg_result` |
| A role, edits, model tiering, or children    | `subagent`                  |
| Several model perspectives on one prompt     | `fusion_*`                  |

Do not delegate what a few direct tool calls finish — read the file, run the
command, answer.

## Background tasks (`bg_run`)

No model involved: dev servers, builds, test suites, watchers, migrations.

- Returns immediately with a task id and a durable output file.
- Never `sleep`, `bg_status`, or `bg_logs` merely to wait. End the turn; the
  completion notification wakes a follow-up turn.
- `isAgent: true` only when the command itself launches an LLM.

## Delegate (`bg_delegate`)

One inspect-only child seeded with a frozen projection of the visible
conversation. Read/search/list tools only — it cannot edit.

- The parent keeps working; retrieve with `bg_result` when the notification
  arrives.
- Facts that exist only inside omitted tool output are not in the projection.
  Restate them in the prompt.

## Fusion (reason, investigate, research, validate)

Fixed candidate → evaluate → merge workflow for a second, third, and fourth
opinion on one bounded question. Children get the workflow input, not the
conversation. `fusion_research` fetches only the URLs you name; it does not
search.

Every surface above is async and notifies on completion. Polling it is a bug.
`bg_run_pi_attested` is opt-in evidence collection, not a general runner.

## Subagents (`subagent`)

Real child Pi sessions with an agent definition: role prompt, model, tools, and
write access. Builtins: `scout` (recon), `researcher` (web/docs), `worker`
(implementation), `reviewer` (review plus small fixes), `oracle` (read-only
second opinion), `delegate` (general).

Use when the work needs any of:

- a **role** — review, adversarial challenge, planning, scouting,
  implementation;
- **writes** — the child edits files (one writer per cwd/worktree);
- **model tiering** — cheap workers, strong reviewers;
- **orchestration** — parallel lanes, `runs.all`, `workflowScript` chains,
  worktree isolation, acceptance gates.

Default to async and yield; the parent is woken on completion. Set
`async: false`
only when this turn cannot end without the result. The parent keeps user intent,
authority, arbitration, and final acceptance.

## `bg_delegate` or a read-only subagent?

Both spawn a child that reads the repo.

- `bg_delegate` — the child only reads, and it needs this conversation as
  context.
- `subagent` (`scout`, `oracle`, `reviewer`) — the child needs a role, a model
  tier, a deliverable shape, or is one lane of a workflow.

Neither one exists to run a shell command. That is `bg_run`.
