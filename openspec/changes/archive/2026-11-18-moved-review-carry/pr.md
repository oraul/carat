fix(pipeline): carry reviews only when moved finds main intact

## Summary

Makes tools/run_state.sh moved carry the reviews over a merge of main only when no file of the change changed and the head matches the new main in every file the change never touched, and records a carried review only when moved itself exited 0 at that head for the commit the review passed at. Before this a merge that put a main-only file back to its old text, such as a landed security fix, printed that the change was the same and carried both reviews; the carry was recorded from a regex over the checker's text, a file named like a git pathspec could empty the comparison, and a failing git diff carried too.

---

## Changes

- Fix moved so it also compares the head with the new main in every file the change never touched and runs the reviews again on any difference
- Fix moved so file names are compared as literal text with grep and never reach git as pathspecs, so a name such as :(exclude)tools no longer empties the comparison
- Fix moved so a failing git diff exits 1 and runs the reviews again instead of carrying them
- Change moved to write a moved record, head and reviewed commit, only on its exit-0 path, and refuse to let set write that key
- Change the review command so a carried review is refused unless the moved record names the current head and the commit of that review's existing pass record
- Change the delivery workflow to record a carried review only after the shell's moved exited 0, no longer from the checker's returned text, and tools/agent_guard.sh to match
- Add tools-test cases for a merge reverting a main-only file, a :(exclude)tools file name, and a failing diff each exiting 1 with no moved record, carried reviews refused without or after a failed moved, a carried review recorded after moved exits 0, and set refusing moved
- Document the stricter carry in README.md and the run_state.sh entry of docs/codebase-map.md
- Record four review findings in docs/findings/moved-review-carry.md and the lane's metrics history

---

## Testing

- Run the security review of the committed diff, pass with high 0, medium 0, low 1, none blocking, the Low recorded in docs/findings/moved-review-carry.md
- Run the quality review, pass with 0 blocking and its advisories, the correctness and missing-test ones recorded as findings and the wording ones fixed
- Run the checker's stages docs-lint, dev-build, test-build, diagnose, test-run, bench-budget, tools-test, gates, and metrics at the checked commit, all pass
- Run the benchmark review, pass with no allocation or round change
- Run make spec-validate after archiving the change, 54 passed and 0 failed
- Run make gates and make docs-lint on the packaged branch, both pass

---

## Notes

Fixes the sprint-16 blocking security finding against moved, delivered first and alone so sprint-16-records can follow it; the change alters no product behavior and is archived with skip-specs. A merge that keeps the change's side of a file main also edited still carries the reviews, and moved still runs from the branch's own copy of the script; both are recorded as findings for a follow-up rather than widened here. The advisory to write the records filter once in moved was dropped as style, and the design and proposal wording advisories were fixed; the README sentence advisory was dropped, since rewording the reviewed README after the reviews would need them again. No tools/rules.sh edit.
