with_entries(
    select(
        .value.sensitive == false
    ) |
    .value |= .value
) |
.hosts = .hosts_non_sensitive |
del(.hosts_non_sensitive)
