chore(run-state): merge near-same backlog notes and prune old entries

## Summary

Makes the sprint groom merge a near-same review note into its existing entry and prune old backlog entries that are fixed or no longer apply, each removal proven against the history before anything is written. The backlog grew by about 35 headings a sprint and never shrank, and the user asked for more backlog throughput while keeping every review note. The planner's sprint mode, already the backlog's only reader, becomes its curator, building on groom-proof's provable removals; no new agent and no new start.

---

## Changes

- Add a `merged` groom line, naming a kept heading and a near-same heading, that appends the near-same entry's reasons and locations under the kept entry and removes its heading, refused for unknown or identical headings, a kept heading removed by another line, a heading merged twice, or a security entry merging into an entry without a severity
- Add a `closed COMMIT HEADING` groom line that removes an old entry only when the commit is in HEAD, follows the commit that added the whole heading, and changes a file the entry names, never for a security entry
- Add a `gone HEADING` groom line that removes an entry whose every named path the history held is absent at HEAD, never for a security entry
- Add a `backlog-oldest` command printing the oldest 50 entries the plan does not already remove, and allow it in the guard's read profile the planner runs under
- Add tools_test cases for each new groom line's accepted and refused paths, a prefixed heading included
- Document the intake and pruning in the planner's sprint mode, sprint-planning, README pipeline step 11, CLAUDE.md Agents, the run_state.sh header, and the code map
- Record the planner's queue, with parts b and c queued as backlog-throughput-b and lsp-tidy moved to Sprint 19, and the groom-proof metrics row

---

## Testing

- Run the security review of the committed diff at 65a5758220b7, pass with high 0, medium 0, low 0
- Run the quality review at 65a5758220b7, pass with 0 blocking and 1 advisory, recorded in docs/findings/backlog-throughput.md
- Run the checker's stages at 65a5758220b7 (docs-lint, dev-build, test-build, test-run, diagnose, bench-budget, tools-test, gates, metrics), all pass
- Run the benchmark comparison at 65a5758220b7, pass with no blocking difference
- Run make spec-validate after the archive, 54 of 54 pass

---

## Notes

This delivers part a of the brief, intake and pruning at groom; parts b, bigger batches of small entries, and c, fix-on-touch entries in a feature delivery's brief, are queued as backlog-throughput-b. It is delivered off the queue at the user's request as a Sprint 18 backlog change in place of lsp-tidy, which moves to Sprint 19. A closed entry names its fixing commit and a gone entry its vanished locations; a security entry still leaves only by listed, fixed, or a merge into another security entry. tools/rules.sh is untouched.
