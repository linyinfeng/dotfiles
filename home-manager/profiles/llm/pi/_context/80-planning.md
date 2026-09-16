# Planning

- 3+ steps, a user-supplied task list, or multi-part instructions →
  `extensions.todo` (in memory, no tokens). An explicit user request is the only
  source of `extensions.create_goal`.
- Never promote a todo list into a goal: goals are user-authorized, persistent
  and audited, todos are session scratch. With an active goal the tool surface is
  larger (`extensions.update_goal`, `extensions.set_goal_tasks`,
  `extensions.update_goal_task`).
- The drafting tools (`extensions.goal_question`,
  `extensions.goal_questionnaire`, `extensions.propose_goal_draft`) exist only
  during `/goal`/`/sisyphus`, where a direct `create_goal` is rejected — the
  draft path keeps the user in the loop.
