### The benchmark phase measures records and docs-only runs (sprint-12-records retro note 4)
- Location: `.claude/workflows/deliver-change.js` benchmark phase; sprint-12-records run state note.4.
- Why: bench took 6,460 of 36,282 output tokens (17.8%) and 10 of 79 calls on sprint-12-records, 15,099 of 127,367 (11.9%) and 23 of 222 calls over the three sprint-records runs, and found allocations and rounds equal to main 3 of 3, never changing a decision.
- Fix: skip the bench phase with its reason when the change touches no file under carat/, bin/, bench/, or the Makefile; accepted when a records run records bench skipped with 0 calls and a carat/ change is still measured.

### groom output needs a hand edit after each records run (sprint-12-records retro note 5)
- Location: `tools/run_state.sh` groom and folded_backlog (about :1851); sprint-12-records run state note.5.
- Why: 2 of the last 3 records runs hand-edited docs/backlog.md after groom (a backticked path to a findings file groom deleted, docs-lint refusing it), and all 3 of sprint-12-records' quality advisories were groom output (headings folded twice from a double append, no blank line before folded headings); reviews took 9,975 of 36,282 output (27.5%).
- Fix: groom leaves no backticked path to a removed findings file, no repeated folded heading, and a blank line before each folded heading; accepted when a tools-test case shows all three and the next records run applies groom with no hand edit.

### The skeptic's disputed-note command double-quotes the finding text (`sprint-security` security Low (4))
- Location: .claude/agents/quality-reviewer.md:41
- Why: the skeptic is told to record a disputed security finding as a double-quoted shell argument, so `$(...)` or backticks in the finding text, which can echo attacker-controlled diff content, would be expanded when the skeptic runs the note command; the shape existed before, and sprint-security narrows it to disputed findings only.
- Fix: have the skeptic single-quote the note text (escape ' as '\'' and turn control characters into spaces), as the workflow's shellWord does, or have the workflow build the disputed-note commands itself from a structured disputed list in the skeptic's result.

### A security finding both reviewers missed may go unrecorded (`sprint-security` quality advisory)
- Location: .claude/agents/quality-reviewer.md:41
- Why: "Record what both missed the same way" now follows the disputed-only form, so a security finding both missed may be noted with a disputed: prefix or not at all.
- Fix: say a missed finding is noted as note CHANGE security "FINDING" (quality as in Periodic mode step 4).

### A /sprint rerun records every security finding again (`sprint-security` quality advisory)
- Location: .claude/workflows/sprint-planning.js:196
- Why: the Notes step runs on every /sprint run and init resumes sprint-N, so a rerun after an incomplete review (partial, a sweep hold, a capped skeptic, now more frequent) appends every security finding again and the planner reads duplicates.
- Fix: skip a note whose text the run state already holds.

### The report's not-recorded suffix and new Sweep line have no test (`sprint-security` quality advisory)
- Location: .claude/workflows/sprint-planning.js:267
- Why: the Security line's "its findings were not recorded" suffix and the Sweep line's new text have no tools_test case, so a regression in what the report says goes unnoticed.
- Fix: pass noted to securityLine so the existing tools_test case covers the suffix, and add a case for the Sweep line.
