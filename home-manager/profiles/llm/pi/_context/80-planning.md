# Planning

- 3+ steps, a user-supplied task list, or multi-part instructions → `todo` (in
  memory, no tokens). An explicit user request is the only source of
  `create_goal`.
- Never promote a todo list into a goal: goals are user-authorized, persistent
  and audited, todos are session scratch. With an active goal the tool surface is
  larger (`update_goal`, `set_goal_tasks`, `update_goal_task`).
- The drafting tools (`goal_question`, `goal_questionnaire`,
  `propose_goal_draft`) exist only during `/goal`/`/sisyphus`, where a direct
  `create_goal` is rejected — the draft path keeps the user in the loop.
