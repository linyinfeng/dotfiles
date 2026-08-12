# Code Comment Rules

Treat the user as a competent developer: never explain obvious code.

**No comment when**: logic is obvious; names already convey intent;
stdlib/framework usage is conventional; control flow is simple.

**Comment when** (explain _why_, not _what_):

- Complex logic — the approach and its complexity
- Hacky workaround — problem, cause, temporary fix, upstream issue
  link
- Non-obvious business rule — the rule itself
- Performance optimization — reason and measured effect
- External dependency / side effect — the dependency and what callers
  must handle

**Style**: short, factual. Never restate the code
(`# iterate over the list`), no comment on an obvious line
(`user = get_user(id)  # Get user by id`).

**Decide**: obvious or well-named → no comment; complex/hacky →
comment; otherwise refactor for clarity.
