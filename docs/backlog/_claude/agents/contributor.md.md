# Backlog: .claude/agents/contributor.md

## The contributor's implement step validates the change twice

- Where: implement steps 2 and 6 of `.claude/agents/contributor.md` (line 34 at `package-clean`), which run `openspec validate <change> --strict` and then `make spec-validate`, whose `validate --all --strict` already covers the change. Quality advisory of `package-clean`.
- Why it matters: two ways to do one check cost a tool call each run and can drift apart.
- Fix outline: keep only `make spec-validate`.
- Category: pipeline
- Added: 2026-11-05

## The backlog append names no entry shape and no route

- Where: `.claude/agents/contributor.md:48` (package step 2) and `.claude/agents/planner.md:25` (`build/plan/backlog.md`). Quality advisories of the `backlog-compaction` review.
- Why it matters: the contributor must append entries to a file it may not read for their shape, and `tools/agent_guard.sh` refuses here-documents, so neither the entry form nor a working append route is stated.
- Fix outline: state the shape (a blank line, a `## ` title, then `- Where:`, `- Why it matters:`, and `- Fix outline:` bullets) and the route (write the entries to a `tmp/` file with the Write tool, then `cat` it `>> docs/backlog.md`) in `contributor.md`, and the same shape in `planner.md` for `build/plan/backlog.md`.
- Also: .claude/agents/planner.md, tools/agent_guard.sh
- Category: pipeline
- Added: 2026-11-11

## The implement step does not say to grep the named backlog entries

- Where: `.claude/agents/contributor.md:34` (implement step 1); `openspec/changes/archive/2026-11-11-backlog-compaction/tasks.md` task 2.4 marks `contributor.md` done for it. Quality advisories of the `backlog-compaction` review.
- Why it matters: the positive rule reaches the contributor only through `CLAUDE.md:208`; the agent file states only the package step's never read it whole.
- Fix outline: add to implement step 1 "when your queue item names backlog entries, Grep `docs/backlog.md` for those entries only".
- Also: openspec/changes/archive/2026-11-11-backlog-compaction/tasks.md, CLAUDE.md
- Category: pipeline
- Added: 2026-11-11

## pr-by-tag quality advisory at .claude/agents/contributor.md:22

- Where: `.claude/agents/contributor.md:22`. Delivery review of `pr-by-tag` (quality advisory) at 742ba5f.
- Why it matters: 'tools/agent_guard.sh refuses both' now follows the two allowed pushes and reads as if the guard refused them.
- Fix outline: say the guard refuses recording a phase or review and any other push.
- Also: tools/agent_guard.sh
- Category: pipeline
- Added: 2026-11-11

## pr-on-push quality advisory at .claude/agents/contributor.md:35

- Where: `.claude/agents/contributor.md:35`. Delivery review of `pr-on-push` (quality advisory) at a2d4b6c.
- Why it matters: the fix commit for the wait timeout also rewords unrelated lines (step 2 drops 'for the archive', step 3 'fill in' to 'add', step 6 drops 'The workflow records the phase from your result.', the Context paragraph), so one commit mixes the fix with edits no finding asked for.
- Fix outline: keep a fix commit to its finding, or say in the body why the lines moved (docs-lint budget).
- Category: pipeline
- Added: 2026-11-11

### Restore the dropped contributor instructions or correct the guard-ref-pin proposal

- Location: .claude/agents/contributor.md:18 (quality advisory, docs; also reported at 26).
- Why: the trim drops instructions ('Every change goes through OpenSpec, however small'; 'For Ruby code, docs/examples.md and docs/spinel-notes.md first'; why no session edits a pull request with a tool) while the proposal says no instruction of either agent changes; CLAUDE.md still covers them.
- Fix: keep a short pointer to docs/examples.md and docs/spinel-notes.md, or correct the proposal's claim.
- Also: docs/examples.md, docs/spinel-notes.md, CLAUDE.md
- Category: pipeline
- Added: 2026-11-14

### The contributor's test and recording rule lost a word

- Location: .claude/agents/contributor.md:22 (sprint-4 review, quality).
- Why: the condensed sentence drops "disable" and the note that agent_guard.sh refuses both, and reads as if a phase or review may be recorded through `run_state.sh push`.
- Fix: restore "disable" and split the test rule and the recording rule into two sentences.
- Category: pipeline
- Added: 2026-11-14

## Quality: byte-trimmed agent prose reads as bare commands the guard refuses

- Location: `.claude/agents/contributor.md:37` (`diagnose-one T=path`, `lint`, `docs-lint`), `.claude/agents/contributor.md:39` (`spec-validate`), and `.claude/agents/planner.md:20` (`then its show <name>`).
- Why it matters: quality advisory. Trimming bytes to stay within the `docs_lint.sh` budgets left target names without their `make`, which read as commands the guard refuses, and left the planner's sentence without its subject; one clear way to do each thing.
- Fix outline: write `make gates spec-validate` at contributor.md:39 and `make test-one T=..., diagnose-one T=..., lint, docs-lint` as one make list at :37, and `then sh tools/run_state.sh show <name>` or `then show <name> of it` in planner.md, making room by pointing to the notes rather than raising a budget.

- untyped-gateway, quality advisory, carat/domain/json.rb:72: duplication: digits? hand-rolls a fourth byte loop beside Parser#digit? (:354, same file) and HistoryCommandHandler.digits? (a one-line regex). Why: four ways to test digits drift apart. Fix: make it text.match?(/\A[0-9]+\z/) as HistoryCommandHandler does, or reuse Parser's digit? instead of the literals 48 and 57.
- untyped-gateway, quality advisory, carat/domain/json.rb:62: object_field and array_element are public although the design's risk mitigation says object_field is called only from field, which verified the Hash. Why: any other caller passes Spinel an unverified Hash. Fix: say in their comment they are reached only through field and element (the codebase has no private_class_method), or fold each [] into a typed local inside field and element.
- untyped-gateway, quality advisory, test/json.rb:71: the check J.field(J.field(read, "a"), "b").is_a?(Hash) ? 1 : nil asks whether an Array is a Hash. Why: it proves nothing about the readers, under a label promising a member of another kind of value is nil. Fix: replace it with J.field(J.reach(read, "a.b"), "c") expecting nil.
- untyped-gateway, quality advisory, docs/spinel-notes.md:47: the same baseline of 1,181 rebuilds is given as 131 s of code generation (untyped-elephant) and then as 152 s (this change), measured on different machines without saying so. Why: a reader compares seconds that are not comparable. Fix: name the machine dependence beside the new seconds or give only the rebuild counts.
- Also: .claude/agents/planner.md, tools/run_state.sh, carat/domain/json.rb, test/json.rb, docs/spinel-notes.md
- Category: pipeline
- Added: 2026-11-15

### The contributor's list of the other agents' phases drops the benchmark
- Location: .claude/agents/contributor.md:14
- Why: the benchmark still runs as its own phase, so the list misleads a reader of the agent; the fix did not fit the file's budget without a trim after the reviews
- Fix: restore benchmark to the list, trimming six bytes elsewhere in the file
- Category: pipeline
- Added: 2026-11-17

### The contributor self-check and the quality reviewer share no blocking checklist
- Location: `.claude/agents/contributor.md` (self-check), `.claude/agents/quality-reviewer.md` (blocking rule)
- Why: quality fails its first pass most often, 66 of 130 changes against check 128/130 and security 125/130; 5 of the last 11 feature rows quality:0; lsp-container-b's fix round (SIGPIPE ending carat on stop) cost implement 153,294 of 264,142 output (58.0%) and put the run over its 200,000 output budget at 229,659 (retro note 11).
- Fix: one blocking checklist both read, or drop the self-check items that never caught a blocker; accepted when the feature lane's quality first pass over the next 10 rows reaches 8 of 10 with implement output no higher than its current median. Queued in `review-demotion`.
- Also: .claude/agents/quality-reviewer.md
- Category: pipeline
- Added: 2026-11-17

### The contributor's self-check and the quality reviewer use different blocking checklists (lsp-container-b retro note 11)
- Location: `.claude/agents/contributor.md` self-check, `.claude/agents/quality-reviewer.md` blocking rules
- Why: quality failed its first pass in lsp-container-b (SIGPIPE ending carat on stop), quality:0 in 5 of the last 11 feature rows and 66 of 130 over all changes against check 128/130 and security 125/130; the fix round cost implement 153,294 of 264,142 output (58.0%) and took the run over its 200,000 output budget (229,659). Adds evidence to "### Quality fails its first pass on about half the runs".
- Fix: one blocking checklist both read, or drop the self-check items that never caught a blocker; accepted when the feature lane's quality first pass over the next 10 rows reaches 8 of 10 with implement output no higher than its current median.
- Also: .claude/agents/quality-reviewer.md
- Category: pipeline
- Added: 2026-11-17

### Quality advisories still dropped at the package step (lsp-container-c retro)
- Location: `.claude/agents/contributor.md` package step 2
- Why: 3 of 3 lsp-container-c advisories (`carat/domain/config.rb:219`, `carat/domain/trusted_roots.rb:48`, `docs/codebase-map.md:100`) went only into the pull request Notes, now 14 of 23 dropped over the last 4 rows with advisories; quality first pass 71/136. For `review-demotion`.
- Fix: remove the contributor's judgment of which advisories to keep; accepted when over the next 5 runs every advisory is fixed or in the change's findings file, 0 dropped.
- Also: carat/domain/config.rb, carat/domain/trusted_roots.rb, docs/codebase-map.md
- Category: pipeline
- Added: 2026-11-17

### The package step applies review advisories to reviewed files and the push is refused (markdown-reading-d retro)
- Location: `.claude/agents/contributor.md` package step; `.claude/workflows/deliver-change.js` package phase
- Why: markdown-reading-d's packaging contributor applied an advisory that reworded a reviewed comment and its code map line, the pre-push gates refused the push twice (gates_failed 2), and both files were put back in new commits, still claiming one marker scan; package took 22 calls against a last-10 feature median of 15.5, 3 of 3 advisories the cause. For `review-demotion`.
- Fix: an advisory whose fix touches a reviewed file goes to the findings file or a fix round, never a package edit; accepted when over the next 5 deliveries with advisories no package-phase push is refused (gates_failed 0).
- Also: .claude/workflows/deliver-change.js
- Category: pipeline
- Added: 2026-11-17

### The contributor's extras ship without their tests (T1 efficiency)
- Location: `.claude/agents/contributor.md`, its self-check step
- Why: motions-search-tidy first.quality 0 on :g and :v reading ~ through compile_search (`carat/use_cases/search/global_command.rb:65`, an extra the proposal named), the round adding 122,352 output tokens (30 percent of 407,893); 21 of 142 recorded quality-blocking notes read behavior change without its test; quality first pass 79/145.
- Fix: the self-check holds each extra the proposal names to its test like a brief entry; accepted when over the next 10 runs no quality-blocking note reads behavior change without its test on code the proposal lists as an extra.
- Also: carat/use_cases/search/global_command.rb
- Category: pipeline
- Added: 2026-11-17

### The contributor's package step drops its no-backlog clause (pipeline-diet quality)
- Location: .claude/agents/contributor.md:47
- Why: out of scope: the package step's 'never opening the backlog' is dropped, the contributor file's only statement of the no-backlog rule, which the brief does not ask to change.
- Fix: restore the clause.
- Category: pipeline
- Added: 2026-11-18

### Unrelated wording trims in the contributor file (pipeline-diet quality)
- Location: .claude/agents/contributor.md:34, :70
- Why: out of scope: unrelated wording trims ('Do the plan notes beside the code' to 'too' at :34, 'Return the result the workflow's schema asks' to 'Return the workflow's schema' at :70) change no behavior the brief names.
- Fix: revert both lines.
- Category: pipeline
- Added: 2026-11-18

### Unclear mode (sprint-20 review quality, contributor.md:83)

- Location: `.claude/agents/contributor.md:83`
- Why: unclear mode: body mode is written only for a red CI scan plus a terse '(--pr-text: text)', while the pull request text review's rewrite reaches the contributor through this mode and only the workflow prompt (deliver-change.js:1262) describes it
- Fix: add one sentence for the text-review rewrite (claims only what the diff holds, pushed with --pr-text, not --ci-fix)
- Category: pipeline
- Added: 2026-11-19

### Feature-lane quality first pass keeps failing after the checklist changes
- Location: .claude/agents/contributor.md (the self-check before a done result)
- Why: 7 of the last 11 feature rows record quality:0, finder-grep (#229) and finder-grep-b both 0 after contributor-checklist (#226); finder-grep-b's one rework round on an untested HIT_ROOM clamp cost 95,622 output tokens, 34% of its 281,571; overall 103/189 (finder-grep-b retro note 10).
- Fix: have the contributor's own check find an untested behavior change before the review; accepted when at least 7 of the next 10 feature rows record quality:1.
- Category: pipeline
- Added: 2026-11-20

### Contributor rule 10 is reported skipped and advisories follow (status-winbar-tabs retro note 7)
- Location: `.claude/agents/contributor.md` rule 10 (re-read the diff with the quality-reviewer instructions).
- Why: both editing starts of status-winbar-tabs reported rule 10 skipped; the quality review then raised 5 advisories at 8573c94c2735, all on added lines, costing rework round 1; quality first pass 126/218 (57.8 percent) against check 206/218 and security 210/218.
- Fix: remove rule 10, or make it bind; accepted when the next five deliveries average no more advisories on contributor-added lines than now (removed) or under 1 (bound).
- Category: pipeline
- Added: 2026-11-21
