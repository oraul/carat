# Queue: backlog

Ordered by `docs/goals.md`; folded findings are in `docs/backlog.md`. Every fix is accepted with `lh` 26.0, `j` 27.0, `insert` 26.0 held.

## Sprint 21

The user-approved exception (2026-11-19, finder-grep note 31): the three are the user's, not backlog-pick batches; `delivery-guards-b`, `merged-record`, and `sprint-count-t0` (Pool 1 to 3) run outside the 3, `delivery-guards-b` right after `spinel-bump`.

1. `spinel-bump` (T2 user request, estimated large, alone in its lane window (shared toolchain and compile cache), critical c Makefile): `SPINEL_REF` is 656 commits behind c0502112d8. Accepted when `make spinel-header` and `make check` pass and the pull request compares allocations, rounds, time per key, and analysis time with main's. Backlog: none.
2. `check-runner-safety` (T1 pipeline defect, security Medium (6), Low (5), estimated large, pushed back 19, the pipeline-defect slot, critical a tools/run_state.sh): `clone_make` (`tools/run_state.sh:529`) links the check clone to the writable `tmp/.toolchain` and `tmp/.spinel`, and the benchmark runs branch code in the delivery clone (`.claude/agents/benchmark.md`), so a stage can write the delivery clone's `.git`, `build/pipeline`, or the Spinel binaries the next check runs. Fix outline: stages and the benchmark cannot write the delivery clone or the shared toolchain. Accepted when tools-test cases fail a check whose stage changes the toolchain or writes the delivery clone by an absolute path. Backlog: "## A check stage can still write the delivery clone by an absolute path", "### Security: the check clone links the toolchain back into the delivery clone (sprint-6 sweep, Medium (6))", "### The check clone shares a writable toolchain (security Low (5))".
3. `use-case-surface-a` (T2 user request, estimated large, part a of 4, critical e carat/use_cases/): use cases expose 293 `attr_reader`s (227 read by the guard in `test/adapters_assembly.rb`, 5 by production code: `show_hover.hover`, `follow_hover.hover`, `show_definition.definition`, `show_completion.source`, `file_requests.files`), and 22 of 103 `call` signatures return no Outcome. The user's design: the public surface is `call` returning an Outcome, collaborators read as instance variables, a private reader only where a concern needs one, the guard reading a wiring ledger `EditorAssembly` fills. Part a: the proposal (the ledger, the 22 calls' mapping) and the first area, its missing edge-case tests first in their own commit. Accepted when that area has no public reader, the assembly test checks the ledger with `equal?`, and the pull request compares analysis time, rounds, binary size, and time per key with main's. Backlog: none.

## Pool

1. `delivery-guards-b` (T1 pipeline defect, user request, estimated large, the exception, critical b .claude/workflows/deliver-change.js): contributor results of "placeholder" stopped quality-first-pass and contributor-tier-routing; "gates clean" met a failed gates stage 3 times. Accepted when tools-test cases show (`deliver-change.js:861`) a placeholder or a head other than the lane's `git rev-parse --short=12 HEAD` refused and restarted once, noted, and a self-check the next check contradicts noted `self-check-mismatch`. Backlog: "### Mid-tier contributor returned a placeholder result".
2. `merged-record` (T1 pipeline defect, user request, estimated small, the exception, critical b tools/run_state.sh): vim-folds-windows held `phase.merge` with `merged` empty, so `review_due` left it out until set by hand; accepted when a tools-test case fails a merge phase recorded without its merged commit.
3. `sprint-count-t0` (T1 pipeline defect, user request, estimated small, the exception, critical b tools/run_state.sh): `review_due` (`:2278`) counted 2 T0 items among sprint-19's 6; accepted when a tools-test case leaves a T0 change out.
4. `pr-trust-lows` (T1 defect, security Medium (4), Lows, estimated large, pushed back 2, backlog-pick batch 1, area 1, absorbs `sprint-review-continuation`): its 10 headings, "## A security review after a quality-only fix reads the whole branch again" to "### Restrict the open-pr edit path to same-repository pull requests (security Low, confidence 4)"; sprint-20 Lows `open_pr.sh:196`, `run_state.sh:1330`.
5. `render-tidy` (T6 with security Low (5), estimated large, pushed back 2, batch 2, area 13): its 10 headings, "### Bracketed paste is never enabled (sprint-14 sweep security Low (5))" to "## DisplayWidth.of_char has no caller"; 2 sprint-19 bracket pair headings.
6. `lsp-tidy` (T6 with security Lows (3), estimated large, pushed back 6, reason: the user's exceptions; first in Sprint 22 by the backlog goal; batch 3, area 17): its 10 headings, "### MakePath and the project .caratrc check follow a link swapped after the probe (sprint-14 sweep security Low (3), Low (3))" to "## The language server client has loose ends".
7. `use-case-surface-b`, `-c`, `-d` (T2 user request, estimated medium each): one area each, its edge-case tests first; the last turns on lint's rule.
8. `check-runner-safety-b` (T1 defect, Lows (4), (3), estimated medium): `tools/run_state.sh:280`, `:439`, `:530`, `:536`; 4 headings.
9. `review-lite-docs` (T1 pipeline, user request, estimated small): settle over README.md and architecture diffs too (`tools/gates.sh:119`), its `tools/rules.sh:78` edit first; "### A settled records-only round can remove security entries unseen (sprint-19 review security Low (5))".
10. `ex-commands-tidy` (T3 security Low (6), estimated medium): `:normal` nests through a project remap; 9 area-12 headings.
11. `file-access-color` (T3 security Lows (3), estimated medium, pushed back 2): `disk_files.rb:33`, `rc_config_gateway.rb:59`, `:61` (sprint-20 sweep), `editor_assembly.rb:489`.
12. `contributor-checklist-b` (T1 pipeline, user request, estimated small): a finding repeated 3 times becomes a check; a fix's test fails with the fix reverted.
13. `test-one-alone` (T4, user request, estimated small): `make test-one T=test/use_cases_plugins.rb` fails alone.
14. `lsp-tidy-b`, `render-tidy-b`, `explorer-tidy` (T6, estimated medium each, `plugin.rb:516`).
15. `skill-guard` (T1 defect, Medium (6), estimated small): `tools/agent_guard.sh:1071`.
16. `vim-compat-fixes` (T6 bugs, estimated medium): `command_grammar.rb:98` (the sweep's unbounded count), `text_objects.rb:356`, `motions.rb:550`, `vim_pattern.rb:134`.
17. `bench-scenarios` (T4, estimated small): 4 skipped (`bench/run.sh:73`); `glyph-audit` (T2 user request, estimated small).
18. `rework-review-repeat` (T1, estimated medium): an advisory-only round re-runs every review; reviews 29.1% of finder-grep's output, 26.5% of contributor-tier-routing's (retros 26, 20); accepted when an advisory-only pass leaves rework unchanged and starts one advisory start.
19. `ci-trust-gaps-b` (T1, Lows, estimated medium): `ci.yml:36`, `open-pr.yml:46` (sprint-20 sweep); `ci-trust-gaps-c`, `toolchain-clean-scope` (T1, estimated small each).
20. `check-clone-toolchain`, `periodic-clear-rules`, `review-scope-pins`, `sprint-security-b`, `backlog-throughput-b`, `check-pass-budget-flag` (finder-grep check 202,930 of 200,000) (T1 defects, estimated medium each).
21. `round-limit-resume`, `open-pr-retry`, `stage-clean`, `tools-test-identity`, `records-plan-apply`, `bench-skip-no-code`, `moved-review-diff`, `advisory-findings-auto`, `merge-output-cap` (retro 21: merge 58,679 output, 24.9%), `scout-prune-step`, `doc-budget-room`, `groom-fold-format`, `merge-main-queue-conflict`, `main-fixed-no-rework`, `resume-no-op`, `package-no-fix`, `planner-delivery-scope`, `pr-text-counts` (finder-grep retro 28), `advisory-repeat-guard` (retro 27: 4 repeats), `tier-price-mid` (T1, estimated small each).
22. `normal-command-fixes` (T3 Low (6), estimated large): `normal_command_handler.rb:62`.
23. `motions-search-tidy-b` (T4, estimated medium), `plugin-host-tidy`, `input-bytes-tidy`, `frame-presenter-tidy`, `motions-search-tidy-c` (T6, estimated medium each).

## Decisions

- Sprint 21 (T2 user request, note 31 item 1): 3 features, 3 backlog; `spinel-bump`, `check-runner-safety`, `use-case-surface-a`.
- Size up (T1): closing-loop 1,418,283 and contributor-tier-routing 1,983,067 both over 1,200,000: the lane's mediums go large.
- Split (T2): `use-case-surface` is large outside the roadmap: part a first, b to d Pool 7.
- Groom (T1): 6 listed, 3 merged; oldest 50 none closed or gone: 9 still hold at HEAD (`ci_scope.sh:99`, `operate.rb:46`, `open_file.rb:46`), 4 name only paths this history never held.
- Groomed (T1): 74 findings (sprint-20 review 6 of 10, sweep 68); 4 folded whole into `finder-grep-b`, `vim-folds-c`.
- Pick (T1): batches 1 to 3 (10 entries each) are Pool 4 to 6; 34 `unmapped:` entries wait for a docs batch.
- Backlog goal (T2, note 31 item 4): Sprint 21 adds 74 entries, removes 9 plus 3 listed; Sprint 22's lane opens with Pool 4 to 6.
- Security first (T0): none; review high 0 medium 0; sweep `partial` high=0 medium=0 low=4, not reviewed plugins, shell-tools.
- Security (T3, item 6): 7 sprint Lows placed: `grep.rb:164`, `plugin.rb:186`, `run_state.sh:1330`, `open_pr.sh:196`, `ci.yml:36`, `open-pr.yml:46`, `rc_config_gateway.rb:61`.
- Calibration (T1): quality first pass sprint-20 1 of 8 (sprint-19 2 of 6); no move before the trial's 6 rows.
- Triage (T1): done (95bf2e0), not repeated.
- Merge gate (T1): no Sprint 21 item edits `tools/rules.sh`.
