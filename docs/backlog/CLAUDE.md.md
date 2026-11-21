# Backlog: CLAUDE.md

## Every agent start receives all of CLAUDE.md

- Where: every agent of `.claude/agents/`, the readers that never edit included; the harness injects `CLAUDE.md` (30,534 bytes) into each custom agent's start, and no frontmatter setting of an agent file leaves it out. Found by `agent-inputs`.
- Why it matters: input dominates a run's tokens (1.0M to 1.6M total against 0.24M to 0.40M output), and a run starts about ten agents, the checker, merger, and benchmark reading rules they never apply.
- Fix outline: cut `CLAUDE.md` to the rules every agent needs, moving the rest to the agent files, the map, or the notes, within the 27,648 bytes `docs-currency` set; if the harness gains a setting that leaves it out of an agent, use it for the agents that never edit. Queued in `docs-index` (queue item 29), since `docs-currency` is archived.
- Category: pipeline
- Added: 2026-11-04

## The roadmap's progress is readable nowhere in one place

- Where: the Status line of `CLAUDE.md` (line 9), which since `docs-currency` points to `docs/architecture.md` section 12, and section 12, which marks only items 4, 5, 7, 8, and 12 as delivered. Quality advisory of `docs-currency` at 19e41a9.
- Why it matters: items 1, 2, 3, 6 (but `:g` and `:v`), 11, and the configuration files of 9 are done too, so an agent planning from section 12 sees less progress than there is, and the short list that said so left `CLAUDE.md`.
- Fix outline: mark each delivered item, and the delivered half of 6, 7, 9, and 12, in section 12, or restore the short item list to the Status line.
- Also: docs/architecture.md
- Category: pipeline
- Added: 2026-11-05

## CLAUDE.md cites the wrong architecture section for concerns

- Where: the concerns bullet of Coding conventions in `CLAUDE.md` (line 247 at 78078ad) cites `docs/architecture.md` section 5.4, but the concerns rule is the last bullet of section 5.3 (`docs/architecture.md` line 184). Quality advisory in `quick-docs`.
- Why it matters: an agent following the citation reads the wrong section and misses the concerns rule.
- Fix outline: cite section 5.3 in `CLAUDE.md`, or move the concerns bullet under 5.4.
- Also: docs/architecture.md
- Category: pipeline
- Added: 2026-11-07

## The docs gate keeps two overlapping CLAUDE.md checks

- Where: `gate_docs` in `tools/gates.sh` line 236 and the `process_change` check at line 265, at 3895e21. Periodic quality advisory. Queue item `implement-contracts-c`.
- Why it matters: the added-files check takes no proposal escape and the newer one takes the stays escape, so one file can pass one and fail the other, and the header does not say which wins.
- Fix outline: fold the added-files check into `process_change`, or state in the header that additions take no escape.
- Also: tools/gates.sh
- Category: pipeline
- Added: 2026-11-09

## The docs credit the periodic review with backlog edits it never makes

- Where: `CLAUDE.md:208` and `README.md:192`. Quality advisory of the `backlog-compaction` review.
- Why it matters: both say the periodic review merges duplicate entries and clears fixed ones, but the periodic reviewers never edit and `/review` fixes nothing, so until `periodic-council` lands nothing does.
- Fix outline: say the periodic quality review reports duplicates and fixed entries and the backlog step of `periodic-council` applies them.
- Also: README.md
- Category: pipeline
- Added: 2026-11-11

### Backlog entry for the stale build/carat.rbs drifts from the entry format (docs/backlog.md:5701)

- Location: docs/backlog.md:5701, the entry the mit-license change added.
- Why: it uses '- Fix:' where entries use '- Fix outline:', and its Location gives no line and unquoted paths, against the entry format CLAUDE.md asks for (location, why, fix outline). Found by the quality review of mit-license (advisory).
- Fix outline: at sprint grooming, change it to '- Location: Makefile:405 (types), build/carat.rbs read by spin --rbs.' and '- Fix outline: ...'.
- Also: Makefile
- Category: pipeline
- Added: 2026-11-15

## CLAUDE.md lost a rule and misstates the start inputs to fit its budget

- Location: CLAUDE.md:204
- Why: the edit drops the rule 'Tasks of one domain may share a change' and rewords open-pr's role, unrelated to the brief, to fit the 30720-byte budget (now 30718), and 'every start given only the brief' misstates that starts also get packs, findings, and logs.
- Fix: restore the rule, say 'every start given the brief', and make room elsewhere.
- Source: quality advisory, brief-only-relay.
- Category: pipeline
- Added: 2026-11-15

### The README and CLAUDE.md still say CI runs every other stage on the pull request

- Location: README.md:189, CLAUDE.md:231
- Why: the checker paragraph says CI runs the rest of CHECK_STAGES on the pull request, and CLAUDE.md that the Makefile records why CI leaves out two, but build now runs only on a push to main (quality advisory, ci-time-tidy-b).
- Fix: say the pull request runs the rest but the release build, which main.yml runs after the merge, and name the third stage in CLAUDE.md.
- Also: README.md, Makefile
- Category: pipeline
- Added: 2026-11-16

### CLAUDE.md's Sprints bullet omits the beyond-the-sprint mark

- Location: CLAUDE.md:213, README.md:196 (sprint-8 review, quality); queued in `hook-one-place`.
- Why: the bullet says the sprint closes at the fifth merge review-due counts and never names the mark it now leaves out; only README.md and run_state.sh name it.
- Fix: add the mark to the Sprints bullet and to planner.md.
- Also: README.md
- Category: pipeline
- Added: 2026-11-16

### CLAUDE.md sits 9 bytes under its docs budget
- Location: CLAUDE.md:1 (tools/docs_lint.sh budget of 30720 bytes)
- Why: CLAUDE.md is 30711 of its 30720 bytes after rework-guards trimmed unrelated lines (the hotfix and release branch examples, the Stack PATH note) to fit, so the next addition fails docs-lint.
- Fix: Move detail to the notes docs CLAUDE.md already points to rather than trimming more examples.
- Also: tools/docs_lint.sh
- Category: pipeline
- Added: 2026-11-17

### CLAUDE.md and planner.md have no bytes left for review fixes
- Location: `CLAUDE.md`, `.claude/agents/planner.md` against docs-lint's limits (planner-split-rule retro note 6).
- Why: CLAUDE.md 30,714 of 30,720 bytes, planner.md 8,189 of 8,192; the split rule left out of CLAUDE.md and 2 of 4 quality advisories deferred for want of bytes.
- Fix: free space by removing repetition, limits unchanged; accepted when the next change touching them lands planner-split-rule quality advisories 3 and 4 and the split rule with docs-lint passing.
- Also: .claude/agents/planner.md
- Category: pipeline
- Added: 2026-11-17

### The CLAUDE.md planner bullet names only build/plan/CHANGE/
- Location: CLAUDE.md:205
- Why: the planner bullet says the planner writes into build/plan/CHANGE/, but its sprint mode and /plan write to build/plan/ (planner.md:25, sprint-planning.js:9), so the bullet misplaces the sprint plan.
- Fix: "into build/plan/ (CHANGE/ in a delivery)" when the bytes allow, with the user's approval, since the wording was approved verbatim.
- Category: pipeline
- Added: 2026-11-17

### Process text of the closing loop is absent from CLAUDE.md and docs/goals.md
- Location: `CLAUDE.md` Agents section (30,713 of 30,720 bytes) and `docs/goals.md` line about own-file advisories fixed in place within the rounds.
- Why: both describe advisories as fixed in place or recorded; the closing loop adds one last start after the rounds, described only in README.md and `docs/contributor-notes.md`.
- Fix: when budget allows, one sentence in the CLAUDE.md contributor bullet and the planner's goals text naming `close-advisories`, once its recorded figures show whether it stays.
- Also: docs/goals.md, README.md, docs/contributor-notes.md
- Category: pipeline
- Added: 2026-11-19

### Docs drift (sprint-20 review quality, CLAUDE.md:41)

- Location: `CLAUDE.md:41`
- Why: docs drift: 'Push once, plus one per CI fix, review fix, moved main, text fix' reads as one push per review fix, moved main, and text fix, while run_state.sh push allows one of each of those three a run and one per CI fix
- Fix: 'plus one per CI fix and one review-fix, moved-main, and text-fix push a run'
- Category: pipeline
- Added: 2026-11-19

### CLAUDE.md:247: the coding conventions still say shared objects are kept (sprint-22 review quality)

- Location: `CLAUDE.md:247`
- Why: the coding conventions still say shared objects are kept in a reader so test/adapters_assembly.rb can check every holder got the one instance, with no mention that use cases under READERLESS_DIRS (discovery/, windows/) have no reader and are checked through the wiring ledger (docs drift)
- Fix: add a clause naming READERLESS_DIRS and the @wiring.record convention, or point to docs/examples.md, which describes it
- Also: test/adapters_assembly.rb, docs/examples.md
- Category: pipeline
- Added: 2026-11-20
