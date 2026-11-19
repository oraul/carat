# Queue: backlog

Ordered by `docs/goals.md`; folded findings are in `docs/backlog.md`. Every fix is accepted with `lh` 26.0, `j` 27.0, `insert` 26.0 held.

## Sprint 21

The user-approved exception (2026-11-19, finder-grep note 31): the three are the user's, not backlog-pick batches; `delivery-guards-b`, `merged-record`, and `sprint-count-t0` (Pool 1 to 3 at ffe84f6) run outside the 3, `delivery-guards-b` next, `spinel-bump` delivered as `spinel-catchup`.

1. `check-runner-safety` (T1 pipeline defect, security Medium (6), Low (5), estimated large, pushed back 19, the pipeline-defect slot, critical a tools/run_state.sh): `clone_make` (`tools/run_state.sh:529`) links the check clone to the writable `tmp/.toolchain` and `tmp/.spinel`, and the benchmark runs branch code in the delivery clone (`.claude/agents/benchmark.md`), so a stage can write the delivery clone's `.git`, `build/pipeline`, or the Spinel binaries the next check runs. Fix outline: stages and the benchmark cannot write the delivery clone or the shared toolchain. Accepted when tools-test cases fail a check whose stage changes the toolchain or writes the delivery clone by an absolute path. Backlog: "## A check stage can still write the delivery clone by an absolute path", "### Security: the check clone links the toolchain back into the delivery clone (sprint-6 sweep, Medium (6))", "### The check clone shares a writable toolchain (security Low (5))".
2. `use-case-surface-a` (T2 user request, estimated large, part a of 4, critical e carat/use_cases/): use cases expose 293 `attr_reader`s (227 read by the guard in `test/adapters_assembly.rb`, 5 by production code: `show_hover.hover`, `follow_hover.hover`, `show_definition.definition`, `show_completion.source`, `file_requests.files`), and 22 of 103 `call` signatures return no Outcome. The user's design: the public surface is `call` returning an Outcome, collaborators read as instance variables, a private reader only where a concern needs one, the guard reading a wiring ledger `EditorAssembly` fills. Part a: the proposal (the ledger, the 22 calls' mapping) and the first area, its missing edge-case tests first in their own commit. Accepted when that area has no public reader, the assembly test checks the ledger with `equal?`, and the pull request compares analysis time, rounds, binary size, and time per key with main's. Backlog: none.

## Pool

1. `delivery-guards-c` (T1 pipeline defect, user request, estimated medium, the rest of `delivery-guards-b` by the split rule, critical b .claude/workflows/deliver-change.js): "gates clean" met a failed gates stage 3 times, and a self-check of match is never compared with the next check (`deliver-change.js:935`). Accepted when a tools-test case shows a self-check the next check contradicts noted `self-check-mismatch` and moving later contributor starts to the session's model.
2. `merge-body-sections` (T1 pipeline defect, estimated medium, critical b .claude/agents/merger.md): squash 5c94cc0 (#234) kept the Summary, 0 of the 4 headings its pr.md holds (merged-record note 8); accepted when a tools-test case fails a merge whose main commit lacks one.
3. `pr-trust-lows` (T1 defect, security Medium (4), Lows, estimated large, pushed back 2, backlog-pick batch 1, area 1, absorbs `sprint-review-continuation`): its 10 headings, "## A security review after a quality-only fix reads the whole branch again" to "### Restrict the open-pr edit path to same-repository pull requests (security Low, confidence 4)"; sprint-20 Lows `open_pr.sh:196`, `run_state.sh:1330`.
4. `render-tidy` (T6 with security Low (5), estimated large, pushed back 2, batch 2, area 13): its 10 headings, "### Bracketed paste is never enabled (sprint-14 sweep security Low (5))" to "## DisplayWidth.of_char has no caller"; 2 sprint-19 bracket pair headings.
5. `lsp-tidy` (T6 with security Lows (3), estimated large, pushed back 6, reason: the user's exceptions; first in Sprint 22 by the backlog goal; batch 3, area 17): its 10 headings, "### MakePath and the project .caratrc check follow a link swapped after the probe (sprint-14 sweep security Low (3), Low (3))" to "## The language server client has loose ends".
6. `use-case-surface-b`, `-c`, `-d` (T2 user request, estimated medium each): one area each, its edge-case tests first; the last turns on lint's rule.
7. `check-runner-safety-b` (T1 defect, Lows (4), (3), estimated medium): `tools/run_state.sh:280`, `:439`, `:530`, `:536`; 4 headings.
8. `review-lite-docs` (T1 pipeline, user request, estimated small): settle over README.md and architecture diffs too (`tools/gates.sh:119`), its `tools/rules.sh:78` edit first; "### A settled records-only round can remove security entries unseen (sprint-19 review security Low (5))".
9. `ex-commands-tidy` (T3 security Low (6), estimated medium): `:normal` nests through a project remap; 9 area-12 headings.
10. `file-access-color` (T3 security Lows (3), estimated medium, pushed back 2): `disk_files.rb:33`, `rc_config_gateway.rb:59`, `:61` (sprint-20 sweep), `editor_assembly.rb:489`.
11. `contributor-checklist-b` (T1 pipeline, user request, estimated small): a finding repeated 3 times becomes a check; a fix's test fails with the fix reverted.
12. `test-one-alone` (T4, user request, estimated small): `make test-one T=test/use_cases_plugins.rb` fails alone.
13. `lsp-tidy-b`, `render-tidy-b`, `explorer-tidy` (T6, estimated medium each, `plugin.rb:516`).
14. `skill-guard` (T1 defect, Medium (6), estimated small): `tools/agent_guard.sh:1071`.
15. `vim-compat-fixes` (T6 bugs, estimated medium): `command_grammar.rb:98` (the sweep's unbounded count), `text_objects.rb:356`, `motions.rb:550`, `vim_pattern.rb:134`.
16. `bench-scenarios` (T4, estimated small): 4 skipped (`bench/run.sh:73`); `glyph-audit` (T2 user request, estimated small).
17. `rework-review-repeat` (T1, estimated medium): an advisory-only round re-runs every review; reviews 29.1% of finder-grep's output, 26.5% of contributor-tier-routing's (retros 26, 20); spinel-catchup retro: 4 of the last 11 lane rows rework 1 with every gate first, bench 5.7% of output; merged-record retro 6: 5 of 11, check 12.6%, reviews 19.0%; accepted when an advisory-only pass leaves rework unchanged and starts one advisory start.
18. `ci-trust-gaps-b` (T1, Lows, estimated medium): `ci.yml:36`, `open-pr.yml:46` (sprint-20 sweep); `ci-trust-gaps-c`, `toolchain-clean-scope` (T1, estimated small each).
19. `check-clone-toolchain`, `periodic-clear-rules`, `review-scope-pins`, `sprint-security-b`, `backlog-throughput-b`, `check-pass-budget-flag` (finder-grep check 202,930, merged-record 211,138 of 200,000; delivery-guards-b check 216,514 of 200,000 yet 973,293 of 1,200,000 total, the check verdict against the final one in 7 of 16 medium rows) (T1 defects, estimated medium each).
20. `round-limit-resume`, `open-pr-retry`, `stage-clean`, `tools-test-identity`, `records-plan-apply`, `bench-skip-no-code` (sprint-20-records bench 9.3% of output), `moved-review-diff`, `advisory-findings-auto` (sprint-20-records reviews 31.2%, closing start closed 0 of 3, merged-record 0 of 1), `merge-output-cap` (retro 21: merge 58,679 output, 24.9%), `scout-prune-step`, `doc-budget-room`, `groom-fold-format` (also an exact heading repeat in one fold, backlog :8754, :8759), `merge-main-queue-conflict`, `main-fixed-no-rework`, `resume-no-op`, `package-no-fix`, `planner-delivery-scope`, `pr-text-counts` (finder-grep retro 28), `advisory-repeat-guard` (retro 27: 4 repeats), `tier-price-mid`, `bench-timing-confirm` (spinel-catchup retro: allocs dot-ciw 66.0 in 10 of 10 rows, us 96.8 to 220.9), `lane-head-record-cost` (delivery-guards-b retro: a record start about 155,000 total, 2 to 4 more per run; accepted when 3 runs show no more record starts) (T1, estimated small each).
21. `normal-command-fixes` (T3 Low (6), estimated large): `normal_command_handler.rb:62`.
22. `motions-search-tidy-b` (T4, estimated medium), `plugin-host-tidy`, `input-bytes-tidy`, `frame-presenter-tidy`, `motions-search-tidy-c` (T6, estimated medium each).

## Decisions

- Delivering (T1 pipeline defect, user request, the exception): `sprint-count-t0`, Pool 1 at 5c94cc0, removed; `review-due` counts 4 of 6, 2 of them outside the 3.
- Estimate medium (T1): the lane's last 14 rows all over small's 500,000 (lowest 636,664), both small rows too; delivery-guards-b, one guard, 973,293 in 57 min.
- No size up (T1): delivery-guards-b 973,293 under; merged-record, no row yet, check 211,138 of 200,000 output (note 5).
- Size check (T1): one count in `sprint_state` (`tools/run_state.sh:2231`) feeding `review_due` :2309, `sprint_row` :2505, groom :2676; 4 cases: no split.
- Critical (T1, rule b): tools/run_state.sh; no `tools/rules.sh` edit.
- Security first (T0): none; no pending periodic finding; open Mediums at confidence 6 and 4, below 8.
- Delivered (T1): `merged-record` merged 5c94cc011f13, medium, rework 1.
- Placed (T1): merged-record note 8 as Pool 2, behind the user's `delivery-guards-c`; notes 6, 7, 5 merged into Pool 17, 20, 19; 1 to 4 quality, handled.
- Exception (T1): the line's three delivered with this; Pool 1, 2 wait for the user or Sprint 22's pipeline slot.
