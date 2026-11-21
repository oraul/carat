# Backlog: README.md

## The README's commands table omits six make targets

- Where: `README.md` line 14, the commands table, which has no row for `make clean`, `make pack`, `make spinel-rev`, or `make help` (line 12 now names `make install`), periodic quality advisory at df5a203, nor for `make metrics` or `make metrics-compare`, periodic quality at 3895e21.
- Why it matters: the map's Build and CI rule gives every command a README line, and goal 12 keeps the README current.
- Fix outline: add one row naming the missing targets, or one row per target, checked against `make help`.
- Category: design
- Added: 2026-11-09

## The README says the merger runs the metric line before its work

- Where: `README.md` (line 192 at `run-budgets`). Quality advisory of `run-budgets`, raised twice.
- Why it matters: since `run-budgets` the merger runs the metric line only inside the green and red lines after CI, and not at all on a pending or stale return, so the README misdescribes when the figures are recorded.
- Fix outline: reword the sentence to say the green and red lines record the figures.
- Category: design
- Added: 2026-11-06

## Completion docs advisories

- Where: `README.md` (line 63 at 334d899), where the raw-mode sentence explaining why Ctrl-S works moved to the end of the completion paragraph; the language-services area of `docs/codebase-map.md` (line 593) names only `test/domain_rpc_framer.rb` for `ControlText`, though `test/domain_fuzzy_match.rb` (line 267 of the map) also holds the `ControlText.plain`, `CompletionItem`, and `CompletionList` tables; the 5.3 bullet of `docs/architecture.md` (line 180) says these use cases answer an unavailable service with an empty response and a message, while completion with no ready source opens nothing and reports nothing. Quality advisories in `completion`.
- Why it matters: the README sentence no longer follows the Ctrl-S sentence it explains, the map hides where the `ControlText.plain` table lives, and the architecture contradicts the completion spec (typing behaves as without completion).
- Fix outline: put the raw-mode sentence back after "Ctrl-S saves ... stay in insert mode." and keep the completion paragraph on its own; name `test/domain_fuzzy_match.rb` for `ControlText.plain` in the language-services line or move those tables to a test named after them; say completion stays silent when its source is not ready, or state the `CompletionPort` route in the 5.1 completion bullet instead.
- Also: docs/codebase-map.md, test/domain_rpc_framer.rb, test/domain_fuzzy_match.rb, docs/architecture.md
- Category: design
- Added: 2026-11-07

## check-isolation's open quality advisories

- Where: `README.md` line 180, the checker sentence; `openspec/changes/archive/2026-11-07-check-isolation/design.md` line 53, the Risks bullet; `passedAt` in `.claude/workflows/deliver-change.js` line 482; the header comment of `tools/agent_guard.sh` lines 28 to 40. Quality advisories in `check-isolation`; its `tools/gates.sh` line 436 and `docs/codebase-map.md` line 50 advisories are those of `merge-gate-integrity` above.
- Why it matters: the README says branch code cannot write the hooks, git configuration, or run states the gates read, while the design and the entry above record that it still can by an absolute path; the archived Risks bullet still calls the clone the longer-term fix it now is; `passedAt` names a phase record's commit `result` and compares `result === head`, which reads as a bug; one header line runs far past the comment's width.
- Fix outline: say "through the paths it is given" in the README as the design does; leave the archived design as the record and point the next design at the absolute-path residual risk; name the parts `first` and `second` or split the phase and review comparisons; rewrap the header comment. Queued in `check-runner-safety`.
- Also: openspec/changes/archive/2026-11-07-check-isolation/design.md, .claude/workflows/deliver-change.js, tools/agent_guard.sh, tools/gates.sh, docs/codebase-map.md
- Category: design
- Added: 2026-11-07

## The README's parameter-info sentence splits a paragraph

- Where: `README.md` line 64 at c1b3a12 (periodic quality). Queued in `docs-index`.
- Why it matters: the sentence follows the raw-mode Ctrl-S note, separating it from the language-service description.
- Fix outline: move it before the raw-mode sentence.
- Category: design
- Added: 2026-11-09

### Quality advisory: README says finder boxes share an edge under every border (README.md:58)

- Location: README.md:58
- Why: docs currency; it says the finder's list and preview boxes share an edge, but under option.winborder none they stand two columns apart.
- Fix: say they share an edge under a drawn border and keep a gap under none.
- Category: design
- Added: 2026-11-14

### Spinel's MIT notice does not travel with the vendored generated header (README.md:212)

- Location: README.md:212, the credit line, and tools/spinel/spinel_rt_responds_generated.h.
- Why: the MIT condition asks that Spinel's copyright and permission notice go with copies of substantial portions; the credit line names the license without carrying that notice for the vendored header. Found by the quality review of mit-license (advisory).
- Fix outline: in a later item, put Spinel's copyright line and MIT notice in a comment at the top of the tools/spinel/ files, or record in the design why the generated method-name tables need none.
- Also: tools/spinel/spinel_rt_responds_generated.h
- Category: design
- Added: 2026-11-15

### The scout step's README line says the area plan's figures are apart

- Location: README.md:187
- Why: the scout step says the area plan's figures are recorded apart from the scouts', but tools/run_state.sh tokens still keys the plan start under the workflow phase Scout, so metric.weighted.scout mixes both (design.md of scout-focus says so).
- Fix: say only phase.areas is apart, or run the area plan under its own phase.
- Also: tools/run_state.sh
- Category: design
- Added: 2026-11-16

### The README omits gt and node (sprint-18 sweep quality)
- Location: `README.md:91`, `README.md:9`; `Makefile:218`.
- Why it matters: the option list lacks gt; the prerequisites lack node, which `make doctor` requires and the js tools cases run.
- Fix outline: add gt beside jumptab; name node as a prerequisite of the checks or drop it from doctor.
- Also: Makefile
- Category: design
- Added: 2026-11-18

### README wording of the miss rule differs from the agent file
- Location: README.md:190
- Why: on lines the last review did not see changed is unclear and differs from the agent file; the quality step also still says the first pass reads every file of the diff to its end, while the agent file says each changed hunk with its enclosing function.
- Fix: say on lines unchanged since the last review, as .claude/agents/quality-reviewer.md:21 does, and use the agent file's reading wording.
- Also: .claude/agents/quality-reviewer.md
- Category: design
- Added: 2026-11-19

### README summary still says fuzzy file finder
- Location: README.md:5
- Why: The summary still calls the finder a fuzzy file finder, while the plugin's class comment and docs/actions.md now describe substring or initials matching. Quality, advisory, docs currency.
- Fix: Say a file finder, as plugin.rb line 8 now does.
- Also: docs/actions.md
- Category: design
- Added: 2026-11-20

### The README names a PRUNE_COUNT all value that does not exist (sprint-24 sweep quality)

- Location: `README.md:196`
- Why: backlog_oldest has no such value.
- Fix: drop the clause.
- Category: design
- Added: 2026-11-21
