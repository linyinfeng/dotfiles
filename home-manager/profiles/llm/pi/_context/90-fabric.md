# Fabric: what stays user-invoked

- Fabric also ships agents, actors, mesh, workflows, councils, fusion, RLM,
  schema enforcement, spec supervision and swarm coordination. Those skills all
  declare `disable-model-invocation: true`, so they are absent from your skill
  catalog and the user runs them as `/skill:fabric-<name>`. Never load one with
  `pi.read`, and never offer one instead of doing the work.
- `fusion` is ambiguous here. `extensions.fusion_reason`, `_investigate`,
  `_research` and `_validate` are the pi-background-tasks tools you may call;
  `/skill:fabric-fusion` is a user-invoked multi-model deliberation you must not
  start.
- The user-invoked fabric layer is not a substitute for `extensions.subagent`,
  `extensions.bg_*` and `extensions.fusion_*` — those remain your delegation
  surface.
