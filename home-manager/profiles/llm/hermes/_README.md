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

The web entrypoints are `https://hermes.li7g.com:8443` and
`https://hermes-proxy.li7g.com`. Both serve the Hermes Dashboard at `/` and
its shared Kanban board at `/kanban`. Nginx requires a Zitadel login through
OAuth2 Proxy for the UI, APIs, and WebSockets. The allowed account is
`lin.yinfeng@outlook.com`, configured by the shared `personal-oidc` profile.
Other single-user applications can use that profile's Nginx authentication
locations and shared `services.personal-oidc.allowedEmails` list. Register
each application's HTTPS callback in the Zitadel Personal Apps client.

Before deploying the host configuration, apply the Zitadel application and
DNS records and refresh the Terraform outputs and host secrets through the
repository's normal deployment workflow. The personal OIDC profile is
enabled by default and requires the exported Personal Apps client ID.

Configure Grafana separately to POST its default JSON to
`https://hermes-proxy.li7g.com/grafana/alerts`. Set the authorization scheme
to `Bearer` and use the `hermes_grafana_webhook_token` secret. This path
uses the dedicated bearer token for machine authentication. The receiver
returns HTTP 204 after Kanban accepts the event for `ops`. Repeated deliveries
reuse the same card while it remains unarchived.

For a local relay, pipe the same JSON to `hermes-team alert` as `agent`. For
other monitor formats, use `hermes-team submit ops 'Alert title'` with the
event on stdin.

All four Profiles run as the same system user. Run
`hermes -p secretary chat` to talk to the secretary.
