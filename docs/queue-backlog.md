# Queue: backlog

Ordered by `docs/goals.md`; folded findings are in `docs/backlog.md`. Every fix is accepted with `lh` 26.0, `j` 27.0, `insert` 26.0 held.

## Sprint 20

The user-approved exception (2026-11-19, match-paren note 13): Sprint 19's two pipeline speedups roll over first, beside the pipeline-defect slot.

The user-approved exception (2026-11-19, "reinforce some rules"): `delivery-guards` and `delivery-guards-b` run before `spinel-bump`, outside the 3.

1. `check-runner-safety` (T1 pipeline defect, security Medium (6), Low (5), estimated medium, pushed back 19, the pipeline-defect slot, the user's rule, backlog-pick batch 1 part a): `clone_make` in `tools/run_state.sh` (`:529`) links the check clone to the writable `tmp/.toolchain` and `tmp/.spinel`, and the benchmark runs branch code in the delivery clone (`.claude/agents/benchmark.md`), so a stage can write the delivery clone's `.git`, `build/pipeline`, or the Spinel binaries the next check runs. Fix outline: the stages and the benchmark cannot write the delivery clone or the shared toolchain. Accepted when tools-test cases fail a check whose stage changes the toolchain or writes the delivery clone by an absolute path. Backlog: "## A check stage can still write the delivery clone by an absolute path", "### Security: the check clone links the toolchain back into the delivery clone (sprint-6 sweep, Medium (6))", "### The check clone shares a writable toolchain (security Low (5))".

## Pool

1. `delivery-guards-b` (T1 pipeline, user request, estimated medium, parts 2 and 3 of `delivery-guards`, the same exception; card rules 1 and 2 mechanical): a contributor result of "placeholder" lost the head and stopped quality-first-pass; match-paren's "gates clean" met a failed gates stage (retro 10), as did contributor-checklist (retro 12) and vim-folds-windows (retro 15). Accepted when tools-test cases show (`deliver-change.js:861`) a placeholder or a head other than the lane's `git rev-parse --short=12 HEAD` refused and restarted once, noted, and a self-check the next check contradicts noted `self-check-mismatch`. Backlog: none.
2. `lsp-tidy` (T6 with Lows (5), (4), (3), estimated medium, pushed back 5, reason: the user's delivery-guards exception; first in Sprint 21 by aging, backlog-pick batch 2): `process_runner.rb:55`, `:124`, `json_rpc_language_gateway.rb:205`, `:430`, `:789`; batch 2's 10 area-17 headings.
3. `spinel-bump` (T2 user request, estimated medium, pushed back 3, reason: `contributor-tier-routing` first; alone in its lane window, the shared toolchain): 656 commits behind c0502112d8; accepted when `make spinel-header` and `make check` pass and allocations, rounds, time per key, and analysis time are compared with main's.
4. `sprint-count-t0` (T1 pipeline defect, estimated small): `review_due` (`tools/run_state.sh:2278`) counted the T0 items groom-security-mark and check-stage-order among sprint-19's 6, so it closed with 4 planned items; accepted when a tools-test case leaves a T0 change out of the count.
5. `check-runner-safety-b` (T1 defect, Lows (4), (3), estimated medium): `tools/run_state.sh:280`, `:439`, `:530`, `:536`; "## A detached check runner outlives a stopped run and shares build/", "## The check verdict is read from a log read agents can write", "## The run state's writer has no lock beside the detached check runner", "## A lost check runner leaves its make running while a second one starts".
6. `review-lite-docs` (T1 pipeline, user request, estimated small, the user's pool): settle a pass over README.md and docs/architecture.md diffs too (`tools/gates.sh:119`, `:359`, `:449`), its `tools/rules.sh:78` edit first; never over a removed records line: "### A settled records-only round can remove security entries unseen (sprint-19 review security Low (5))".
7. `pr-trust-lows` (T1 defect, security Medium (4), Lows, estimated medium, pushed back 1): `tools/spec_validate.sh:17`, `tools/open_pr.sh:118`, `:190`, `open-pr.yml:39`; 4 headings.
8. `ex-commands-tidy` (T3 security Low (6), estimated medium, backlog-pick batch 3): "### :normal can nest through a project remap until the editor hangs (vim-line-commands-c security Low (6))" and batch 3's 9 area-12 headings.
9. `render-tidy` (T6 with security Low (5), estimated medium, pushed back 1): `screen_presenter.rb:30`, `frame_presenter.rb:569`, `:382`, `:201`, `:1246`; its 5 headings, "### The bracket pair key multiplies by a bare number (sprint-19 review quality)", "### The bracket pair table has no multibyte or scrolled row (sprint-19 review quality)".
10. `file-access-color` (T3 security Lows (3), (3), estimated medium, pushed back 1): `disk_files.rb:33`, `:57`, `rc_config_gateway.rb:59`, `editor_assembly.rb:489`; 4 headings.
11. `contributor-checklist-b` (T1 pipeline, user request, estimated small, parts b and d, after `doc-budget-room`): a finding repeated 3 times becomes a lint or gates check; the brief names the area's edge cases; a fix's test fails with the fix reverted (card rule 7 as an instruction) and covers helpers a fix adds (cursor-and-messages retro 20, quality-first-pass retro 27).
12. `test-one-alone` (T4, user request, estimated small): `make test-one T=test/use_cases_plugins.rb` fails alone (void values in `list_undo.rb`, `walk_history.rb`, `dispatcher.rb`).
13. `lsp-tidy-b`, `render-tidy-b` (T6, estimated medium each): 6 and 5 headings.
14. `skill-guard` (T1 defect, Medium (6), estimated small): the Skill tool is in no hook matcher (`tools/agent_guard.sh:1071`).
15. `explorer-tidy` (T6 with a bug, estimated medium, pushed back 5, reason: backlog-pick first): `plugin.rb:516`; 10 headings.
16. `vim-compat-fixes` (T6 bugs, estimated medium): `command_grammar.rb:98`, `text_objects.rb:356`, `motions.rb:550`, `vim_pattern.rb:134`.
17. `bench-scenarios` (T4, estimated small): 4 scenarios skipped (`bench/run.sh:73`).
18. `glyph-audit` (T2 user request, estimated small): 5 glyphs mean two things each.
19. `sprint-review-continuation` (T1 defect, Low (5), estimated medium): `sprint-planning.js:104`, `:175`.
20. `backlog-throughput-b` (T1, user request, estimated medium): +35 headings a sprint.
21. `round-limit-resume`, `open-pr-retry`, `stage-clean`, `tools-test-identity` (T1 defects, estimated small each).
22. `rework-review-repeat` (T1, estimated medium): later rounds repeat notes and block on fix code, and an advisory-only round re-runs every review (sprint-19-records: reviews 13,756 of 34,522 output tokens, 40%, rework 1 from 0 blocking; delivery-guards retro 25; vim-folds-windows retro 14: round 3 blocked on advisory fix code, 127,138 output tokens); closing-loop retro 10: two advisory paths, rework 2 of 3, round 2 advisory-only (0 blocking); accepted when an advisory-only pass leaves rework unchanged and starts one advisory start; match-paren retro 11, quality-first-pass retro 26, "### Advisory-only fix-in-place rounds count as rework (contributor-tier-trial retro 8)", "### An advisory-only fix round re-runs every review (sprint-19-records retro 5)".
23. `check-clone-toolchain`, `periodic-clear-rules` (T1 defects, Medium (6), estimated medium each, pushed back 2): 4 and 7 headings, less those `check-runner-safety` lists.
24. `review-scope-pins` (T1 defect, Medium (4), estimated medium); `sprint-security-b` (T1 defect, Lows, estimated medium): `tools/gates.sh:112`.
25. `ci-trust-gaps-b`, `ci-trust-gaps-c` (T1, Lows, estimated medium): `ci.yml:54`; `toolchain-clean-scope` (T1 defect, estimated small): `Makefile:203`.
26. `check-pass-budget-flag` (T1 defect, estimated medium): check passes of 153,640 to 573,120 against 200,000.
27. `records-plan-apply`, `bench-skip-no-code` (with "### The benchmark starts on a docs-only change for want of a recorded measurement (sprint-19-records retro 6)"), `moved-review-diff`, `advisory-findings-auto`, `merge-output-cap`, `scout-prune-step` (delivery-guards retro 24), `doc-budget-room` (contributor-checklist retro 14: 4 of 9 advisories at 6,995 of 6,999 bytes), `groom-fold-format` (with "### SECURITY_MARK matches security and a severity word anywhere in a long entry (sprint-19 review quality)"), `merge-main-queue-conflict`, `main-fixed-no-rework`, `resume-no-op` ("### A resumed implement start that commits nothing costs a full implementation (contributor-tier-trial retro 9)"), `package-no-fix` (cursor-and-messages retro 21), `planner-delivery-scope` (contributor-checklist retro 13: plan 13.7% to 19.4% of output), `pr-text-counts` (closing-loop retro 11, note 12: 2 hand-written finding counts wrong, pr_text_fixes 1, pushes 2; accepted when a wrong count is refused before the first push) (T1, estimated small each).
28. `normal-command-fixes` (T3 Low (6), estimated large): `normal_command_handler.rb:62`.
29. `motions-search-tidy-b` (T4, estimated medium), `plugin-host-tidy`, `input-bytes-tidy`, `frame-presenter-tidy`, `motions-search-tidy-c` (T6, estimated medium each).
30. `tier-price-mid` (T1 defect, estimated small, the user's pool): `tools/run_state.sh:2009` prices a mid-tier start at the cheap price; "### The token weighting prices a mid-tier start at the cheap tier's price".

## Decisions

- Delivered (T1 user request): `contributor-tier-routing` leaves Sprint 20 as its 6th of 6 (sprint-20 5 of 6 merged); its and `closing-loop`'s exception lines dropped as delivered (closing-loop merged 32ea3a932f49).
- Estimate medium (T1): contributor-checklist 1,116,087 / 64 min, delivery-guards 1,166,435 / 61 min, closing-loop 1,418,283 / 81 min; of the last two only closing-loop over 1,200,000, no size up.
- No split (T1, the user's one-change request): 1 map area (1 Build and CI), 3 acceptance cases of one start-profile choice; a round-limit stop splits off the escalation.
- Critical (T1, rule (b)): the change edits `.claude/workflows/` and `.claude/agents/`; this run keeps `agent/session`, the routing live after the merge.
- Doc budgets (T1): `contributor.md` 6,997 of 6,999 bytes, `planner.md` 8,179 of 8,192; room by moving prose out.
- Security first (T0), none open: no pending `review.periodic-*`; sprint-19 review Low (5) only.
- Merge gate (T1): the brief edits no `tools/rules.sh`.
- Retro (T1): closing-loop 10 to Pool 22, 11 (note 12 its evidence) to Pool 27 as `pr-text-counts`.
- Overrun (T1): closing-loop 1,418,283 total of 1,200,000 in 81 min, recorded, no item.
