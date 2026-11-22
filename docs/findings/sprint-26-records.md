
## tools/run_state.sh groom: security entries removed without a named fixing commit

- Location: `tools/run_state.sh` (groom), `docs/queue-backlog.md` Groom line.
- Why it matters: groom removed four security Low entries (held-finding and unpushed-finding notes, the skeptic's quoted note) citing only counts, so a later reader cannot trace that they were closed by evidence; the fix exists in 9e4aca0 (#289).
- Fix outline: make groom refuse to remove a security-category entry unless a fixing commit is named, and record each removed security entry with that commit in the Groom proof line or groomed.md. This round only cites 9e4aca0 in the sprint-26 Groom line, briefly, the queue file being at its budget.
