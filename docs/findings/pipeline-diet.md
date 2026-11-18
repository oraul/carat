### plan-needed skips the planner for a security note recorded after a later sprint plan (pipeline-diet security Low (3))
- Location: tools/run_state.sh:2613 (plan_needed)
- Why: plan-needed now skips the planner for a pending change's `security` notes (PLAN_NOTES includes security) whenever any sprint-N-records change merged after it; a security note recorded on that change after the sprint planner ran would never be placed by a planner, so an advisory security finding could sit unqueued. The blocking periodic-security check above the loop is unchanged, so no blocking finding is affected.
- Fix: In plan_needed, apply placed_by_sprint only to retro and overrun notes and keep `security` (and `quality`) notes always triggering the planner, or compare each note's recording time with the sprint-records merge time instead of the change's merge commit.

### The contributor's package step drops its no-backlog clause (pipeline-diet quality)
- Location: .claude/agents/contributor.md:47
- Why: out of scope: the package step's 'never opening the backlog' is dropped, the contributor file's only statement of the no-backlog rule, which the brief does not ask to change.
- Fix: restore the clause.

### Unrelated wording trims in the contributor file (pipeline-diet quality)
- Location: .claude/agents/contributor.md:34, :70
- Why: out of scope: unrelated wording trims ('Do the plan notes beside the code' to 'too' at :34, 'Return the result the workflow's schema asks' to 'Return the workflow's schema' at :70) change no behavior the brief names.
- Fix: revert both lines.

### The proposal and the contributor disagree on when reviewed-edits runs (pipeline-diet quality)
- Location: openspec/changes/archive/2026-11-18-pipeline-diet/proposal.md:13 (was openspec/changes/pipeline-diet/proposal.md:13), .claude/agents/contributor.md:49
- Why: docs drift: the proposal says the package step runs reviewed-edits before each commit, while .claude/agents/contributor.md:49 runs it once in step 4 before the push, after the records commits.
- Fix: state one rule in both (before each commit, or once before the push with a restoring commit).

### scoutTargets matches a location as a substring of the brief (pipeline-diet quality)
- Location: .claude/workflows/deliver-change.js:195 (scoutTargets)
- Why: loose match: scoutTargets names an area when String(brief).includes(pathOf(l)), so a directory or prefix location (tools/, carat/domain) counts as named whenever the brief names any file under it, skipping its scout.
- Fix: match the location's path as a whole token of the brief (delimited by backticks, spaces, or punctuation).

### reviewed-edits fails open when git diff fails (pipeline-diet quality)
- Location: tools/run_state.sh:1692 (reviewed_edits)
- Why: fail-open: reviewed_edits discards git's errors and chains git diff && git ls-files, so a failing git diff yields an empty list and 'none since the security review' with exit 0.
- Fix: run git diff outside the 2>/dev/null pipeline and return 1 when it fails.

### docs-lint's own queue item skip needs a symbolic branch (pipeline-diet quality)
- Location: tools/docs_lint.sh:134 (own_change)
- Why: own_change reads only a symbolic branch, so a detached checkout (CI's pull_request merge ref) never skips the own queue item; harmless today since plan-apply removes the item before the push, but the comment claims only the check clone.
- Fix: say so in the comment, or fall back to GITHUB_HEAD_REF.
