fix(tools): require proof for groom's backlog removals

## Summary

Makes groom remove a backlog entry only on proof drawn from the sprint itself: a listed removal needs a change the sprint merged whose queue item names the heading, a fixed removal needs a commit inside the sprint's range that changes a file the entry names, and the duplicate guard refuses only entries carrying a security severity marker. Before this, any archived change or any ancestor commit, even the root, let a security entry leave unfixed, while the guard refused any text containing the word security and so stopped sprint-17-records on a duplicate that only quoted the Security first section.

---

## Changes

- Change groom's listed proof to accept only a change among the sprint's merged changes whose queue item, wrapped lines joined, holds the whole heading, bounded so a longer or deeper heading does not count
- Change groom's fixed proof to accept only a commit in HEAD after the sprint's base, which must name a commit, that changes a file named in the entry's heading or Location or Where lines as a whole path token
- Change the duplicate guard to refuse only an entry with a security severity marker (security High, Medium, Low, or disputed, or a severity and confidence pair), so an entry that merely mentions security can leave as a duplicate
- Keep exception_item reading both the parent's and the merged commit's queue through the shared queue item helper, so review-due and the sprint row count the same exceptions as before
- Add tools-test cases that refuse a listed change outside the sprint, a listed item lacking the heading, a prefix or deeper heading, a fixed commit at or before the sprint's base or touching no file of the entry, and a sibling path, and that remove a duplicate whose text only mentions security
- Document the new proofs in the groom header, the planner agent's fixed line, the README's grooming step, and the codebase map
- Record five non-blocking findings in docs/findings/groom-proof.md

---

## Testing

- Run the security review on the committed diff at 9d6a478cf0da, pass with no High, Medium, or Low finding blocking
- Run the checker's stages at 9d6a478cf0da (diagnose, docs-lint, dev-build, test-build, bench-budget, tools-test, gates, test-run, metrics), all pass
- Run the quality review at 9d6a478cf0da, pass with no blocking finding and one advisory recorded
- Run the benchmark review at 9d6a478cf0da, pass
- Run make spec-validate after archiving, 54 passed and 0 failed

---

## Notes

This is part a of Sprint 18 backlog item 1 as the planner split it; part b, sprint-review-continuation (the sprint security continuation that drops differently spelled unreviewed files and the capped sprint quality review with no continuation in sprint-planning.js), is queued separately in docs/queue-backlog.md. No backlog entry is removed here: the duplicate that stopped sprint-17-records leaves only through a later groom run under these proofs. tools/rules.sh is not edited, and no file of the feature lane is touched.
