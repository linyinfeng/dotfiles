# Code Comment Rules

Comment _why_, never _what_. Never restate the code (`# iterate over the list`)
and never explain an obvious line (`user = get_user(id)  # Get user by id`).

Comment only when the code cannot say it itself:

- Complex logic — the approach and its complexity
- Hacky workaround — problem, cause, temporary fix, upstream issue link
- Non-obvious business rule — the rule itself
- Performance optimization — reason and measured effect
- External dependency / side effect — the dependency and what callers must handle

Short and factual. Otherwise refactor for clarity instead of commenting.
