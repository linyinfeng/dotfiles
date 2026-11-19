# Hermes team

The `agent` user profile enables `world.profiles.llm.hermes`.
One gateway dispatches cards to `maintainer`, `ops`, `secretary`, and
`team-maintainer`. The service seeds missing configuration and role instructions
under `~/.hermes`. The initial model is the `hermes` alias on LiteLLM. The gateway
loads the existing SOPS key into each Profile at service startup. Hermes owns
subsequent edits, so you can switch providers later with its model picker.

The maintainer sends code changes to `hermes-team code <checkout>`, passing
the task on stdin. This uses the service user's Codex CLI and login, with
`gpt-6.2-sol` at `medium` reasoning effort. Sign in with `codex login` as
`agent` before dispatching implementation work.

For local evaluation with the new files still untracked, use the flake reference
`path:$PWD#<host>` from the repository root.

Run these commands as `agent` after deploying the configuration.

```sh
systemctl --user status hermes-team.target hermes-team.service
hermes -p default kanban --board default assignees
printf '%s\n' 'Ask ops and maintainer to review failed-release triage.' |
  hermes-team submit secretary 'Review failed-release triage'
hermes -p default kanban --board default list
```

When the secretary calls a meeting, it creates input cards assigned to the
participants and a synthesis card that waits on their results. Read the results
and follow-ups with `hermes -p default kanban --board default show <task-id>`.
These reviews are asynchronous and recorded in Kanban. Hermes Desktop group
chats can be set up separately if wanted.

`hermes-team.target` starts the gateway, monitoring timer, configured GitHub
polling timer, and existing Codex app-server when enabled. The monitor runs
on unit failure and once per minute. It assigns each unhealthy unit directly
to `team-maintainer` once per incident. The role can inspect journals, retry
jobs, and restart the team's user services. If the gateway is down, incidents
wait in Kanban while systemd attempts to restart it.

The `agent` profile polls GitHub every ten minutes using littlenano's saved
`gh` token. The poller checks the token's identity before reading notifications.
To supply a token from a runtime file, set
`programs.hermes-team.github.tokenFile`. GitHub accepts the `notifications` or
`repo` scope. Polling leaves the inbox unread and deduplicates on thread ID and
update time while the corresponding card remains unarchived. Access to
repository details uses the service user's `gh` configuration.

Pipe Alertmanager webhook JSON from your alert relay into `hermes-team alert`
as `agent`. For a different monitor, use `hermes-team submit ops 'Alert title'`
with its event on stdin. This module provides the command to invoke and does
not run an HTTP receiver. The board is the initial reporting destination.

All four Profiles run as the same system user. Run
`hermes -p secretary chat` to talk to the secretary.
