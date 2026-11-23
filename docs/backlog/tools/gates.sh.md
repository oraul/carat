# Backlog: tools/gates.sh

## The merge's stages gate cannot pass a renamed or removed stage

- Where: `tools/gates.sh` line 195, the merge's stages gate, which reads `CHECK_STAGES` from main's Makefile with `sed`, while `tools/run_state.sh check` reads the list with `make -s stages`. Quality advisory at d820b39 in `pipeline-speed-b`; the archived design of `pipeline-speed-b` does not cover the case.
- Why it matters: a change that renames or removes a stage cannot pass its own merge, since main's list names a stage the branch never ran, and the stage list now has two readers that can disagree.
- Fix outline: use one reader of the list for both scripts, and accept a stage main names that the branch's `CHECK_STAGES` dropped when the branch's diff removes it from the Makefile (or record the rename in the run state), with a `tools/tools_test.sh` case. Queued in `merge-gate-tidy`.
- Also: Makefile, tools/run_state.sh, tools/tools_test.sh
- Category: pipeline
- Added: 2026-11-04

## The content gate skips files git treats as binary

- Where: `tools/gates.sh` line 126 (`gate_content` reads `git log -p`, which prints no lines for a file with a NUL byte or one `.gitattributes` marks `-diff` or `binary`, and the merge gates run from the branch's checkout, so the branch can set them). Security Low (6) of `backup-secret-scan`; raised to periodic security Medium (7) at b0dd342 (`tools/gates.sh` line 179). Since `url-email-guard`, `tools/scan_text.sh` prints a `note:` line naming such a file in the content gate's output ("a binary file, not scanned"), but does not refuse it; the refusal stays here.
- Why it matters: a committed secret in such a file passes the secret, URL, email, and model checks.
- Fix outline: pass `--text` and `--no-textconv` to the `git log -p` scan, or refuse an added binary file and a `.gitattributes` change setting `diff`, `binary`, or `textconv` unless a reviewer allows it, with a `tools/tools_test.sh` case. Queued in `content-gate-gaps`.
- Also: tools/scan_text.sh, tools/tools_test.sh
- Category: security
- Added: 2026-11-05

## No case covers a secret only in a merge resolution

- Where: `tools/gates.sh` line 126 (the content gate scans with `-m` so a merge's resolution is read) and `tools/tools_test.sh` lines 1324 to 1351 (every secret case is a linear commit). Periodic quality advisory at d386c74.
- Why it matters: dropping `-m` would let a secret introduced while resolving a merge pass `make tools-test`.
- Fix outline: add a case where the secret appears only in a merge commit's resolution and the gate refuses it. Queued in `content-gate-gaps`.
- Also: tools/tools_test.sh
- Category: pipeline
- Added: 2026-11-05

## The gates header says pre-push runs static

- Where: the mode list at the top of `tools/gates.sh` (line 41 at `package-clean`), which says pre-push is static, security, stages. Quality advisory of `package-clean`. At 38628bb the header still omits that `gate_attribution` is left out of the pre-push group (`tools/gates.sh` line 455, periodic quality). Queued in `merge-gate-tidy`.
- Why it matters: static now adds the attribution gate, which pre-push deliberately leaves out (the gates stage runs it), so a reader trusting the header expects a check the push never makes.
- Fix outline: list pre-push as origin, trailer, content, snapshots, docs, scenarios, cases, security, stages, noting attribution runs through the gates stage.
- Category: pipeline
- Added: 2026-11-05

## The attribution gate matches its values anywhere in the settings file

- Where: `gate_attribution` in `tools/gates.sh` (line 336 at `package-clean`), which greps the three values as fixed strings over the whole of `.claude/settings.json`. Quality advisory of `package-clean`.
- Why it matters: a matching `pr` or `sessionUrl` line outside the attribution object passes while the attribution object itself could still allow pull request text or a session link.
- Fix outline: cut the attribution block by its lines (a sed range from the attribution line to its closing brace) and run the greps on that block, with a `tools/tools_test.sh` case of a value outside it.
- Also: .claude/settings.json, tools/tools_test.sh
- Category: pipeline
- Added: 2026-11-05

## merge-gate-integrity's open quality advisories

- Where: at e368486 on the unpushed commits: `tools/gates.sh` line 436 (the gated failures report under an empty or the `pr-body` gate), line 136 (a hosted origin judged by a denylist while `tools/agent_guard.sh` line 347 and `.claude/workflows/deliver-change.js` line 438 use other forms), line 41 (the origin gate's header line stops mid-phrase); `docs/codebase-map.md` line 50 (the `rules.sh` entry lost its separator). Quality advisories in `merge-gate-integrity`.
- Why it matters: a failed gated write names the wrong gate, one origin rule has three diverging definitions, and two documents misread.
- Fix outline: set the gate name before each gated call, keep one allowlist pattern in `tools/rules.sh` used by all three, and repair both lines. Queued in item 45 of `docs/queue.md`, the batch of backlog items.
- Also: tools/agent_guard.sh, .claude/workflows/deliver-change.js, docs/codebase-map.md, tools/rules.sh
- Category: pipeline
- Added: 2026-11-07

## A gate after a failed one prints its ok line

- Where: `tools/gates.sh` line 122 at cd87445: each gate takes `start=$failed` and prints ok unless `failed` changed, while `bad` sets `failed=1`. Periodic quality at cd87445.
- Why it matters: after one gate of a group (pre-push, merge) fails, every later gate prints ok even when it also failed, so the output contradicts itself and hides a second failure.
- Fix outline: count failures in `bad` or keep a per-gate flag, with a `tools/tools_test.sh` case of two failing gates. Queued in `merge-gate-tidy`.
- Also: tools/tools_test.sh
- Category: pipeline
- Added: 2026-11-07

## The cases gate passes every changed tool script on one added case

- Where: `gate_cases` in `tools/gates.sh` (line 242, the check at line 253 at 4f653d2) and its comment, which say a case per script, and the row in `README.md` line 40 that says a case for every changed tool script. Two quality advisories in `implement-contracts`.
- Why it matters: the gate names the changed scripts one by one, but one added `expect` line for any script satisfies all of them, so a branch changing `gates.sh` and `run_state.sh` passes with only a gates case, and the README and the comment promise more than the gate checks.
- Fix outline: for each changed script require an added `expect` line whose command word is the script's basename, with a case in `tools/tools_test.sh`; or reword the README row and the comment to an added case when a tool script changes.
- Also: README.md, tools/tools_test.sh
- Category: pipeline
- Added: 2026-11-07

## The docs and scenarios gates split changed path names unquoted

- Where: `gate_docs` in `tools/gates.sh` line 250 (`stays`, nested, reading the caller's `proposals`) and 251 (`for p in $proposals`), and `gate_scenarios` line 279 (`for spec in $deltas`), at 3895e21. Periodic security Low (4) and periodic quality. Queue item `content-gate-gaps`.
- Why it matters: a branch path under `openspec/changes` with a space or a glob character makes the scenarios gate read another spec, skipping a delta's scenarios, or the stays check read another proposal.
- Fix outline: a top-level `stays` function; read names with `git diff --name-only -z` into `while IFS= read -r` loops under `set -f`, each quoted; cases for a spaced and a globbed path.
- Category: security
- Added: 2026-11-09

## The docs gate accepts a self-written unchanged line as proof

- Where: the `unchanged, REASON` attestation of `gate_docs` in `tools/gates.sh`. Retrospective of `implement-contracts-b` (#86). Queue item `implement-contracts-c`.
- Why it matters: #86's one quality blocker was README and help-list drift behind an untrue `README.md unchanged` line the gate accepted; quality first pass 0 there and 17 of 50 overall, doc prose 9 of 47 recorded blockers.
- Fix outline: a case where a branch changes a target's help or a gate list and attests the README unchanged fails the gate; the acceptance is doc-prose blockers at 0 over the next five runs.
- Also: README.md
- Category: pipeline
- Added: 2026-11-09

## The scenarios gate counts a name found anywhere under test/

- Where: `gate_scenarios` in `tools/gates.sh` line 300 at 3895e21. Periodic quality advisory. Queue item `implement-contracts-c`.
- Why it matters: a scenario passes when its name appears, in any case, as a substring of any file under `test/`, snapshots included, so a short name counts as tested by coincidence.
- Fix outline: match the name only in `.rb` test files and as a whole label or comment.
- Category: pipeline
- Added: 2026-11-09

## The docs and scenarios gates misjudge their inputs

- Where: `tools/gates.sh` line 250 (`gate_docs` defines `stays` inside its body), line 238 against 262 (two overlapping CLAUDE.md checks, one excused cause printing two FAIL lines), line 288 (`gate_scenarios` accepts a name found anywhere under `test/` or in `tools/tools_test.sh` fixtures, or as a substring). Periodic quality at 8d8832f, queued in `content-gate-gaps`.
- Why it matters: a scenario with no proving test passes when a fixture holds its words, and a proposal's excuse line is refused by the older check.
- Fix outline: define helpers at top level; fold the two CLAUDE.md checks into one; match a scenario only as a whole label or comment outside the fixtures, with cases.
- Also: CLAUDE.md, tools/tools_test.sh
- Category: pipeline
- Added: 2026-11-10

## gate_records reads its review commit unchecked

- Where: `tools/gates.sh:436`. Periodic quality.
- Why it matters: every other gate checks a run-state commit as hex and passes `--end-of-options`.
- Fix outline: the same check as `gate_stages`. Queue item `content-gate-gaps`.
- Category: pipeline
- Added: 2026-11-10

## The content gates drop the scanner's exit status

- Where: `report()` in `tools/gates.sh:189` (also 197 and 491) and `tools/docs_lint.sh:79`. Quality advisory of `url-email-guard`.
- Why it matters: `report()` reads only the scanner's output, so a scanner error (exit 2 from `mktemp`, `awk`, or a missing file) leaves the content, pr-body, and docs content checks printing ok, while `tools/pr_scan.sh` does check the status.
- Fix outline: keep the scanner's status (run it into a variable, not through `sort` in a pipeline) and call `bad()` when it is 2, with a `tools/tools_test.sh` case. Queue item `content-gate-gaps`.
- Also: tools/docs_lint.sh, tools/pr_scan.sh, tools/tools_test.sh
- Category: pipeline
- Added: 2026-11-10

## The content gate's header comment has a doubled close

- Where: `tools/gates.sh:13`. Quality advisory of `url-email-guard`.
- Why it matters: the header reads `a literal password or token); (tools/scan_text.sh); no commit adds`, a doubled close from the inserted line, which misreads.
- Fix outline: write `a literal password or token), through tools/scan_text.sh; no commit adds`. Queue item: backlog batches (comment wraps).
- Also: tools/scan_text.sh
- Category: pipeline
- Added: 2026-11-10

## Trusted tooling reads origin/main through replace refs

- Where: every read of `origin/main` by trusted tooling (the origin gate in `tools/gates.sh`, `tools/agent_guard.sh`, and the run state's base reads). Security Medium (5) of the `hooks-path-fix` review, not fixed by `remove-commit-hooks`.
- Why it matters: a `refs/replace/` ref in the clone makes git return other objects for `origin/main`, so a check that trusts main's content can be shown content main never held.
- Fix outline: set `GIT_NO_REPLACE_OBJECTS=1` wherever trusted tooling reads `origin/main`, and refuse `refs/replace` in the origin gate and the guard, each with a `tools/tools_test.sh` case. Queue item `guard-lows`.
- Also: tools/agent_guard.sh, tools/tools_test.sh
- Category: security
- Added: 2026-11-11

## Small tidy-ups found at bd86828

- Where: dead code at `tools/gates.sh:79` and `tools/docs_lint.sh:23` (`TAB`), `carat/domain/options.rb:93` (`KEYHINTS_DELAY`), `carat/use_cases/ex/ex_table.rb:56` (`@index` never read); stale comments at `tools/docs_lint.sh:12` and :27, `carat/use_cases/plugins/ui_requests.rb:112`; the variable `report` shadowing the function at `tools/docs_lint.sh:67`; per-call tallies in instance variables at `carat/use_cases/history/walk_history.rb:32`; `carat/use_cases/repeat_last.rb:49` resets `replaying` without `ensure`; `carat/use_cases/plugins/plugin_host.rb:78` builds a second `ResolveInside` outside `EditorAssembly`; `carat/use_cases/plugins/plugin_events.rb:142` queues an unwanted resize event; `carat/domain/syntax_cache.rb:159` repeats `start_of`; `tools/spec_validate.sh:129` erases the first failed preview. Periodic quality.
- Why it matters: each is a second way to do one thing, a rule of CLAUDE.md, or a lost diagnostic.
- Fix outline: fix each in the batch of its domain, with a row where behavior changes. Queue item: backlog batches.
- Also: tools/docs_lint.sh, carat/domain/options.rb, carat/use_cases/ex/ex_table.rb, carat/use_cases/plugins/ui_requests.rb, carat/use_cases/history/walk_history.rb, carat/use_cases/repeat_last.rb, carat/use_cases/plugins/plugin_host.rb, carat/use_cases/plugins/plugin_events.rb, carat/domain/syntax_cache.rb, tools/spec_validate.sh, CLAUDE.md
- Category: pipeline
- Added: 2026-11-11

## delivery-speed quality advisory at tools/gates.sh:489

- Where: `tools/gates.sh:489`. Delivery review of `delivery-speed` (quality advisory) at 2dcfd3d.
- Why it matters: the session-line pattern refuses any word session followed by a colon anywhere in a line, such as a Notes sentence about the next session:, a false refusal of a valid body.
- Fix outline: anchor it to a line start, as in ^ *(claude-)?session([ _-]?(id.
- Category: pipeline
- Added: 2026-11-11

## delivery-speed quality advisory at tools/gates.sh:35

- Where: `tools/gates.sh:35`. Delivery review of `delivery-speed` (quality advisory) at 2dcfd3d.
- Why it matters: the header still says the stages gate requires every canonical stage from CHECK_STAGES, while stage_list now reads FAST_STAGES first.
- Fix outline: say FAST_STAGES, else CHECK_STAGES.
- Category: pipeline
- Added: 2026-11-11

## The records-only path list is kept by hand in three places

- Source: quality review of sprints-gate, advisory.
- Location: tools/gates.sh:113 (`settled_at`), tools/run_state.sh:223 (`TEST_ONLY`), tools/ci_scope.sh:45 (`documentation()`).
- Why: one clear way: the records-only path list now differs between `settled_at` (with docs/sprints.tsv) and `TEST_ONLY` and `documentation()` (without it), three hand-kept copies of one list that drift, so a groom write is not treated alike by the gates, the stage carry, the fix scope, and CI.
- Fix: name the planning-records pattern once and use it in all three, or add docs/sprints.tsv to `TEST_ONLY` and `ci_scope` in a follow-up.
- Also: tools/run_state.sh, tools/ci_scope.sh, docs/sprints.tsv
- Category: pipeline
- Added: 2026-11-12

## Findings of sprints-gate after its package step

- security Low (3) tools/gates.sh:113 settled_at exempts any edit to docs/sprints.tsv, not only an appended row, so after the review a commit could rewrite the last sprint row's 'last' column. That moves sprint_base in tools/run_state.sh sprint_state and shrinks the combined diff the sprint-end security review covers. Each change keeps its own security review, and the PR scan still reads the edit.; 
- Also: docs/sprints.tsv, tools/run_state.sh
- Category: security
- Added: 2026-11-12

### The gates split file lists on spaces

- Location: tools/gates.sh:224 and :299 (sprint-4 sweep, quality advisory).
- Why: the snapshots and scenarios loops split paths on spaces, so the scenarios gate skips a delta spec whose path holds one and fails open.
- Fix: read paths line by line as gate_content does.
- Category: pipeline
- Added: 2026-11-14

### The merge gate and resume trust review records branch code can write

- Location: tools/gates.sh:415, tools/run_state.sh:610 (sprint-8 sweep, security Medium (6)); queued in `gate-object-pin`.
- Why: gate_passed and the resume read run-state review records that executed branch code can write, and the check clone links back into the project through tmp/.toolchain.
- Fix: keep review records where branch code cannot write them (a workflow-held key, a signed record, or check runs the workflow posts), verify them in the gate and the resume, and drop the link back.
- Also: tools/run_state.sh
- Category: security
- Added: 2026-11-16

### The docs gate holds two rules for one agent-file case
- Location: tools/gates.sh:260-263 and 286-290
- Why: an added or removed agent, command, or workflow file needs a CLAUDE.md change without the proposal escape at 260, while 286-290 accepts "- CLAUDE.md: unchanged, REASON" for every change of the same files. Folded into tools-docs-tidy.
- Fix: drop the process part of 260-263 and let process_change decide, keeping target_change for the README check.
- Also: CLAUDE.md
- Category: pipeline
- Added: 2026-11-17

### gates.sh's header misstates the stages source

- Location: tools/gates.sh:39, :355 (sweep, quality).
- Why: the header says CHECK_STAGES while stage_list reads FAST_STAGES first.
- Fix outline: say STAGES, else FAST_STAGES, else CHECK_STAGES.
- Category: pipeline
- Added: 2026-11-17

### gate_pushes passes a non-numeric count

- Location: tools/gates.sh:397 (sweep, quality).
- Why: -gt on a non-numeric pushes, ci_fixes, or review_fixes errors and the gate prints ok.
- Fix outline: refuse a value that is not digits.
- Category: pipeline
- Added: 2026-11-17

### groom_row reads the shared sprint marker, refusing a records row merged from main (quality, behavior cost)
- Location: tools/gates.sh:128
- Why: groom_row reads the marker in the shared build/plan, so a lane that merged main's records-only sprint row after its reviews has it refused once the planner writes the next sprint's marker, and a review re-runs needlessly.
- Fix: accept a sprint row already on BASE (brought by a merge from main), or name the cost in the design's Risks.
- Category: pipeline
- Added: 2026-11-17

### Tools gates fail open on edge inputs (sprint-14 sweep quality)

- Location: tools/gates.sh:333 (gate_cases: one expect line anywhere satisfies every changed script); tools/gates.sh:266 (has() matches a path as a regex); tools/open_pr.sh:123 (WAIT_STEP 0 loops forever); tools/metrics.sh:71 (measure reports a stale file with status 0).
- Why: each check passes or hangs on an input it should refuse.
- Fix outline: an expect line naming each changed script, grep -F, a positive step, die on a failed write; tools-test cases. Queued in `tools-fail-open`.
- Also: tools/open_pr.sh, tools/metrics.sh
- Category: pipeline
- Added: 2026-11-17

### Shell helpers are copied across four tools scripts (sprint-14 sweep quality)

- Location: tools/gates.sh:86 (bad, ok), tools/docs_lint.sh:37, tools/ci_scope.sh:65 (hex), the log pipeline of tools/gates.sh:222 in tools/pr_scan.sh:49.
- Why: duplication; a fix to one copy misses the others.
- Fix outline: keep the helpers once in tools/rules.sh and the pipeline behind one scan_text.sh option; a rules.sh edit lands alone first. Queued in `tools-docs-tidy`.
- Also: tools/docs_lint.sh, tools/ci_scope.sh, tools/pr_scan.sh, tools/rules.sh
- Category: pipeline
- Added: 2026-11-17

## Two defects are recorded twice in the backlog

- Location: docs/backlog.md:7470 (duplication), with :7380, :7375, and :7476.
- Why: the folded merge-record-check findings and the groomed sprint-14 entries record the same two defects twice: 'groom_row trusts history rows the branch can append after review' (:7380) against 'groom_row compares newline-stripped rows and trusts untracked inputs' (:7470), both at tools/gates.sh:131, and 'squash_commit falls back to HEAD' (:7375) against 'merged_at without a pr accepts any ancestor of HEAD' (:7476).
- Fix: fold each pair into one entry at the next grooming (backlog-dups), keeping the sprint-14 wording and the security Low (4) rating.
- Category: security
- Added: 2026-11-17

### Findings gate docs say BASE where the code uses the fork point
- Location: tools/gates.sh:29, :505, :524
- Why: the usage line says headings at BASE, the gate_findings comment mixes the fork point with BASE..HEAD, and the failure message says present at the base, while the code reads the fork point and fork..HEAD
- Fix: say the fork point of BASE and HEAD and fork..HEAD in all three
- Category: pipeline
- Added: 2026-11-19

### Comment drift (sprint-20 review quality, gates.sh:30)

- Location: `tools/gates.sh:30`
- Why: comment drift: the header says the findings gate compares headings 'at BASE', but gate_findings compares the merge-base fork point (line 517), and its comment line 505 overruns the wrap
- Fix: name the fork point in the header and rewrap lines 504 to 509
- Category: pipeline
- Added: 2026-11-19

### tools/gates.sh:595: pre-push runs the static gates without gate_attribution, though the (sprint-22 sweep quality)

- Location: `tools/gates.sh:595`
- Why: pre-push runs the static gates without gate_attribution, though the usage (line 62) says pre-push is origin, static, security, stages
- Fix: call gate_attribution in pre-push, or reword the usage
- Category: pipeline
- Added: 2026-11-20

### tools/gates.sh:43: the usage says stages reads STAGES else CHECK_STAGES while (sprint-22 sweep quality)

- Location: `tools/gates.sh:43`
- Why: the usage says stages reads STAGES else CHECK_STAGES while stage_list (line 374) prefers FAST_STAGES, and line 46 says pushes allows one push plus one per CI fix and one review fix, omitting the main-moved and text pushes gate_pushes counts
- Fix: update both usage lines
- Category: pipeline
- Added: 2026-11-20

### tools/gates.sh:340: the comment says the cases gate works per script (sprint-22 sweep quality)

- Location: `tools/gates.sh:340`
- Why: the comment says the cases gate works per script, but gate_cases accepts one added expect line anywhere in tools_test.sh for every changed script
- Fix: reword the comment, or require an added case naming each changed script
- Category: pipeline
- Added: 2026-11-20

### INSTRUCTION_RECORDS_RE is defined twice beside the rules file both scripts source (`review-trust-lows` quality advisory)
- Location: `tools/gates.sh:117`, `tools/run_state.sh:465`, `tools/tools_test.sh` ("rules: the instruction records are the gates'"), `tools/rules.sh:69`
- Why: the same pattern lives in two scripts that both source `tools/rules.sh`, held equal only by a test, so a later edit of one copy is a test failure rather than one edit; this change may not edit `tools/rules.sh`, the merge gate's own rules.
- Fix: in a separate rules change landing first, alone, move `INSTRUCTION_RECORDS_RE` beside `RECORDS_RE` in `tools/rules.sh`, drop the two copies and the equality test.
- Merged: ### INSTRUCTION_RECORDS_RE is defined twice and held equal by a test (review-trust-lows quality advisory, raised twice)
- Location: tools/gates.sh:117 and tools/run_state.sh:465 (also reported at :466)
- Why: both scripts source tools/rules.sh, yet each keeps its own copy of the line, held equal only by the tools-test case "rules: the instruction records are the gates'", so one rule has two homes.
- Fix: in a separate tools/rules.sh change landing first and alone, move INSTRUCTION_RECORDS_RE beside RECORDS_RE in tools/rules.sh, drop both copies and the equality test.
- Also: tools/run_state.sh, tools/tools_test.sh, tools/rules.sh
- Category: pipeline
- Added: 2026-11-21

### Queue edits after a security pass reach the next brief unreviewed (sprint-24 review security Low (3))

- Location: `tools/gates.sh:117`, `tools/run_state.sh:466`
- Why: INSTRUCTION_RECORDS_RE names only `docs/goals.md`, so a commit after the security pass that edits only a `docs/queue-*.md` line merges under the earlier review, and the line reaches the next contributor as instructions nobody reviewed.
- Fix: add the lane queues' item lines to the instruction records, or re-review a queue-only diff with the scanner and a light review; a tools-test case fails before the fix.
- Also: tools/run_state.sh, docs/goals.md
- Category: security
- Added: 2026-11-21

### TAB is set and unused in two scripts (sprint-24 sweep quality)

- Location: `tools/gates.sh:85`, `tools/docs_lint.sh:35`
- Why: dead lines.
- Fix: delete both.
- Also: tools/docs_lint.sh
- Category: pipeline
- Added: 2026-11-21

### The gates usage header misstates stages and pushes (sprint-24 sweep quality)

- Location: `tools/gates.sh:44`, `:47`, `:385`
- Why: stage_list reads FAST_STAGES first, and gate_pushes also allows the main-moved and pull request text pushes.
- Fix: update both entries.
- Category: pipeline
- Added: 2026-11-21

### The gate_cases comment asks a case per script (sprint-24 sweep quality)

- Location: `tools/gates.sh:351`
- Why: the gate passes on one expect line for any number of changed scripts.
- Fix: reword to the one-case rule, or check per script.
- Category: pipeline
- Added: 2026-11-21

### The gates accept a tracked symbolic link under the records-only paths
- Location: tools/gates.sh, tools/rules.sh (RECORDS_RE, docs/backlog/.+\.md$)
- Why: file_entries now refuses to write through a symbolic link under docs/backlog/, but a commit adding such a link still lands as records-only after the security review was recorded; another writer of those paths (plan-apply, history) could follow it.
- Fix: have the merge gates refuse a tracked symbolic link (git ls-files -s mode 120000) under the RECORDS_RE paths, in a rules change of its own since it edits tools/rules.sh or the gate reading it.
- Also: tools/rules.sh
- Category: pipeline
- Added: 2026-11-21

### The gates header and comments disagree with the code at tools/gates.sh:64 (sprint-28 sweep quality, notes 46, 47)

- Location: tools/gates.sh:47, :50, :64, :352, :607
- Why: pre-push is said to run attribution (it does not); stages names CHECK_STAGES though FAST_STAGES is read first; pushes omits main-moved and text; gate_cases passes on one expect line however many scripts changed.
- Fix: align the header and comment with the code, or add gate_attribution to pre-push and require a case per changed script.
- Category: pipeline
- Added: 2026-11-22

### gate_records passes a run-state value to git rev-parse unchecked at tools/gates.sh:503 (sprint-28 sweep quality, note 59, security point unexamined)

- Location: tools/gates.sh:503
- Why: unlike the other gates it checks neither hex form nor end-of-options before rev-parse.
- Fix: refuse a non-hex value and pass `--end-of-options`; for the security reviewer to judge.
- Category: pipeline
- Added: 2026-11-22

### The findings gate still trusts a plain entry's gone, duplicate, and merged plan lines
- Location: tools/gates.sh:carrier_unproven
- Why: a plain (non-security) entry removed from docs/findings/ passes when the local plan's groom.txt holds any gone, duplicate, or merged line for its heading, or a bare "- Merged:" line names it; groom's proofs of those kinds (paths gone at HEAD, a location named by another heading) need the entry in the backlog, which no longer stands after groom, so the gate cannot repeat them. A contributor-written plan line can still delete a plain entry. Security entries are covered: they leave only by a verified listed or fixed line or a merged line under a security entry holding the body.
- Fix: have groom write the proof it checked (the paths held, the location named) beside each removal into a tracked record, such as the sprint's row file, and let the gate compare it, or file removed plain entries' headings in the pull request's archived change so the gate reads tracked text only.
- Category: pipeline
- Added: 2026-11-22

### The carrier allowance of the findings gate takes proof that groom itself would refuse
- Location: tools/gates.sh carrier_unproven (the `- Merged:` and groom.txt branches)
- Why: security Low (4). A carrier contributor can delete a security finding by adding a bare `- Merged: ### HEADING` line under any backlog entry, or by writing a `listed x ### HEADING` or `fixed x ### HEADING` line into build/plan/groom.txt, which the guard leaves writable; groom itself would refuse both. This change's task 4.6 already requires a security entry's `- Merged:` line to sit under a security entry with its body after it and hands `listed` and `fixed` lines to `groom-proof`; what remains is that the plan file is still a local file the contributor can write.
- Fix: accept a groom.txt line only after the checks groom applies (for listed, a sprint change whose item lists the heading; for fixed, a commit in the sprint's range that touches the entry), or rely on the docs/backlog evidence at HEAD alone and stop reading the local plan file.
- Category: security
- Added: 2026-11-22

### carrier_unproven accepts a removed entry whose bare heading stands anywhere under docs/backlog
- Location: tools/gates.sh carrier_unproven (near line 647)
- Why: security Low (4). A carrier contributor can add only the `### HEADING` line to a backlog file and delete the entry's body and severity from docs/findings, and the gate passes; the merged_security_kept check requires the body for the merged form only.
- Fix: for a security entry filed under its heading, require the same body check as merged_security_kept: the entry's non-heading lines (its Why, Location, and severity) must stand under that heading in docs/backlog at HEAD, else the entry is unproven.
none
- Category: security
- Added: 2026-11-22

### The findings gate files a security entry by its heading alone at tools/gates.sh:662 (sprint-30 review security Low (6))

- Location: tools/gates.sh:662 (carrier_unproven)
- Why: the findings gate lets a branch carrying the sprint's groom row remove a docs/findings security entry when only its heading line stands anywhere under docs/backlog/, since carrier_unproven runs the heading check before the SECURITY_MARK check; a misled contributor can delete a High finding and add its bare heading to any backlog file, and its severity, location, and fix are lost, as nothing else gates docs/backlog.
- Fix: run the security check first; count a security entry as filed only when its heading and its body lines stand under one security entry at HEAD (as merged_security_kept checks for Merged lines), else require a proven listed or fixed groom line; accepted when a tools-test case filing a security heading without its body is refused.
- Category: security
- Added: 2026-11-23

### groom_row chains [ -z row_ok ] || test || at tools/gates.sh:172 (sprint-30 sweep quality, note 18)

- Location: tools/gates.sh:172
- Why: groom_row chains [ -z row_ok ] || test || row_ok= three times, which reads as cleverness
- Fix: an if chain that sets row_ok once, the temporary files removed after it
- Category: pipeline
- Added: 2026-11-23
