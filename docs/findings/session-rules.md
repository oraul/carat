### CLAUDE.md has 16 bytes of room under its docs-lint budget
- Location: `CLAUDE.md` (30,704 bytes), `tools/docs_lint.sh:58` (30,720).
- Why: the session-rules section was paid for by deleting restated prose, and the next addition to `CLAUDE.md` fails `make docs-lint` until more prose is cut or the budget is raised, which is a reviewed decision of its own.
- Fix: move rule detail that binds only a workflow or an agent from `CLAUDE.md` into `docs/goals.md` or `docs/contributor-notes.md` where it has no budget, or raise the budget in its own change.

### The main session's standing rules are prose with no enforcement
- Location: `CLAUDE.md` Main session, `docs/goals.md` Main session; the tooling side of rule 2 is the queued `plan-brief-amend`.
- Why: nothing refuses a brief amended after its run started, a cost report naming only one token figure, or a skipped step of the after-merge routine; and after a resume under the same run id `tokens` refuses the run as already counted (`resume-tokens-id`), so rules 3 and 6 can only say the figure is unrecorded.
- Fix: `plan-brief-amend` for rule 2, `resume-tokens-id` and `stopped-total-unset` for the totals; a check that the after-merge routine's steps are recorded in the run state.
