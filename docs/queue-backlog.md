# Queue: backlog

Ordered by `docs/goals.md`; folded findings are in `docs/backlog.md`. Every fix is accepted with `lh` 26.0, `j` 27.0, `insert` 26.0 held.

## Sprint 20

The user-approved exception (2026-11-19, match-paren note 13): Sprint 19's two pipeline speedups roll over first, beside the pipeline-defect slot.

1. `contributor-checklist` (T1 pipeline, user request, estimated medium, parts a and c, rolled over): quality fails first on 78 of 176 runs from findings a checklist catches (plugin-lazy-activate: a stale test expectation, a raise branch untested); the self-check (`.claude/agents/contributor.md:38`) names no edge case. Fix outline: a checklist from real findings (empty range, CRLF, UTF-16 and multi-byte, trailing blanks, last line, empty buffer; a test per behavior change; an existing helper searched first; comments, docs, and spec text match the code), and a self-review of the diff with the quality reviewer's instructions, within contributor.md's budget. Accepted when contributor.md's self-check names each point and the self-review, docs-lint budgets hold, and quality passes first on 8 of the next 10 runs. Backlog: "### The quality review fails its first pass most often, and its round costs most (plugin-lazy-activate retro)", "### The contributor returns work the quality review blocks on its first pass (plugin-lazy-activate retro 11)".
2. `check-runner-safety` (T1 pipeline defect, security Medium (6), Low (5), estimated medium, pushed back 19, the pipeline-defect slot, the user's rule, backlog-pick batch 1 part a): `clone_make` in `tools/run_state.sh` (`:529`) links the check clone to the writable `tmp/.toolchain` and `tmp/.spinel`, and the benchmark runs branch code in the delivery clone (`.claude/agents/benchmark.md`), so a stage can write the delivery clone's `.git`, `build/pipeline`, or the Spinel binaries the next check runs. Fix outline: the stages and the benchmark cannot write the delivery clone or the shared toolchain (a sandbox, or a toolchain hash checked before each check and the benchmark in a check clone). Accepted when tools-test cases fail a check whose stage changes the toolchain or writes the delivery clone by an absolute path. Backlog: "## A check stage can still write the delivery clone by an absolute path", "### Security: the check clone links the toolchain back into the delivery clone (sprint-6 sweep, Medium (6))", "### The check clone shares a writable toolchain (security Low (5))".

## Pool

1. `lsp-tidy` (T6 with Lows (5), (4), (3), estimated medium, pushed back 4, reason: the user's roll-over and security-first rule of note 13 took its slot; first in Sprint 21, backlog-pick batch 2): `process_runner.rb:55`, `:124`, `json_rpc_language_gateway.rb:205`, `:430`, `:789`; batch 2's 10 area-17 headings.
2. `spinel-bump` (T2 user request, estimated medium, pushed back 1, same reason; alone in its lane window, the shared toolchain): 656 commits behind c0502112d8; accepted when `make spinel-header` and `make check` pass and allocations, rounds, time per key, and analysis time are compared with main's.
3. `sprint-count-t0` (T1 pipeline defect, estimated small): `review_due` (`tools/run_state.sh:2278`) counted the T0 items groom-security-mark and check-stage-order among sprint-19's 6, so it closed with 4 planned items; accepted when a tools-test case leaves a T0 change out of the count.
4. `check-runner-safety-b` (T1 defect, Lows (4), (3), estimated medium): `tools/run_state.sh:280`, `:439`, `:530`, `:536`; "## A detached check runner outlives a stopped run and shares build/", "## The check verdict is read from a log read agents can write", "## The run state's writer has no lock beside the detached check runner", "## A lost check runner leaves its make running while a second one starts".
5. `review-lite-docs` (T1 pipeline, user request, estimated small, the user's pool): settle a pass over README.md and docs/architecture.md diffs too (`tools/gates.sh:119`, `:359`, `:449`), its `tools/rules.sh:78` edit first; never over a removed records line: "### A settled records-only round can remove security entries unseen (sprint-19 review security Low (5))".
6. `pr-trust-lows` (T1 defect, security Medium (4), Lows, estimated medium, pushed back 1): `tools/spec_validate.sh:17`, `tools/open_pr.sh:118`, `:190`, `open-pr.yml:39`; 4 headings.
7. `ex-commands-tidy` (T3 security Low (6), estimated medium, backlog-pick batch 3): "### :normal can nest through a project remap until the editor hangs (vim-line-commands-c security Low (6))" and batch 3's 9 area-12 headings.
8. `render-tidy` (T6 with security Low (5), estimated medium, pushed back 1): `screen_presenter.rb:30`, `frame_presenter.rb:569`, `:382`, `:201`, `:1246`; its 5 headings, "### The bracket pair key multiplies by a bare number (sprint-19 review quality)", "### The bracket pair table has no multibyte or scrolled row (sprint-19 review quality)".
9. `file-access-color` (T3 security Lows (3), (3), estimated medium, pushed back 1): `disk_files.rb:33`, `:57`, `rc_config_gateway.rb:59`, `editor_assembly.rb:489`; 4 headings.
10. `contributor-checklist-b` (T1 pipeline, user request, estimated small, parts b and d, after `doc-budget-room`): a finding repeated 3 times becomes a lint or gates check; the brief names the area's edge cases.
11. `test-one-alone` (T4, user request, estimated small): `make test-one T=test/use_cases_plugins.rb` fails alone (void values in `list_undo.rb`, `walk_history.rb`, `dispatcher.rb`).
12. `lsp-tidy-b`, `render-tidy-b` (T6, estimated medium each): 6 and 5 headings.
13. `skill-guard` (T1 defect, Medium (6), estimated small): the Skill tool is in no hook matcher (`tools/agent_guard.sh:1071`).
14. `explorer-tidy` (T6 with a bug, estimated medium, pushed back 5, reason: backlog-pick first): `plugin.rb:516`; 10 headings.
15. `vim-compat-fixes` (T6 bugs, estimated medium): `command_grammar.rb:98`, `text_objects.rb:356`, `motions.rb:550`, `vim_pattern.rb:134`.
16. `bench-scenarios` (T4, estimated small): 4 scenarios skipped (`bench/run.sh:73`).
17. `glyph-audit` (T2 user request, estimated small): 5 glyphs mean two things each.
18. `sprint-review-continuation` (T1 defect, Low (5), estimated medium): `sprint-planning.js:104`, `:175`.
19. `backlog-throughput-b` (T1, user request, estimated medium): +35 headings a sprint.
20. `round-limit-resume`, `open-pr-retry`, `stage-clean`, `tools-test-identity` (T1 defects, estimated small each); `pr-testing-truth` (T1 defect, estimated small): match-paren retro 10, gates failed first on a commit the contributor reported clean.
21. `rework-review-repeat` (T1, estimated medium): later rounds repeat notes and block on fix code, and an advisory-only round re-runs every review (sprint-19-records: reviews 13,756 of 34,522 output tokens, 40%, rework 1 from 0 blocking); match-paren retro 11 (2 advisories drawn by fixes), "### Advisory-only fix-in-place rounds count as rework (contributor-tier-trial retro 8)", "### An advisory-only fix round re-runs every review (sprint-19-records retro 5)".
22. `check-clone-toolchain`, `periodic-clear-rules` (T1 defects, Medium (6), estimated medium each, pushed back 2): 4 and 7 headings, less those `check-runner-safety` lists.
23. `review-scope-pins` (T1 defect, Medium (4), estimated medium); `sprint-security-b` (T1 defect, Lows, estimated medium): `tools/gates.sh:112`.
24. `ci-trust-gaps-b`, `ci-trust-gaps-c` (T1, Lows, estimated medium): `ci.yml:54`; `toolchain-clean-scope` (T1 defect, estimated small): `Makefile:203`.
25. `check-pass-budget-flag` (T1 defect, estimated medium): check passes of 153,640 to 573,120 against 200,000.
26. `records-plan-apply`, `bench-skip-no-code` (with "### The benchmark starts on a docs-only change for want of a recorded measurement (sprint-19-records retro 6)"), `moved-review-diff`, `advisory-findings-auto`, `merge-output-cap`, `scout-prune-step`, `doc-budget-room`, `groom-fold-format` (with "### SECURITY_MARK matches security and a severity word anywhere in a long entry (sprint-19 review quality)"), `merge-main-queue-conflict`, `main-fixed-no-rework`, `resume-no-op` ("### A resumed implement start that commits nothing costs a full implementation (contributor-tier-trial retro 9)") (T1, estimated small each).
27. `normal-command-fixes` (T3 Low (6), estimated large): `normal_command_handler.rb:62`.
28. `motions-search-tidy-b` (T4, estimated medium), `plugin-host-tidy`, `input-bytes-tidy`, `frame-presenter-tidy`, `motions-search-tidy-c` (T6, estimated medium each).
29. `tier-price-mid` (T1 defect, estimated small, the user's pool): `tools/run_state.sh:2009` prices a mid-tier start at the cheap price; "### The token weighting prices a mid-tier start at the cheap tier's price".

## Decisions

- Delivered (T1 pipeline, user request, the exception of note 13): `quality-first-pass` leaves Sprint 20; quality first pass 99/178 against check 172/178 and security 171/178 (status).
- Sprint 20, 3 features, 3 backlog (T1): `contributor-checklist` and `check-runner-safety` (Medium (6)) remain, sprint-19 quality 2/6 first pass (`docs/sprints.tsv`).
- Security first (T0), none open: no High or Medium at confidence 8 or above; sprint-19-records security high=0 medium=0.
- Estimate medium (T1): check-stage-order 823,438 / 39 min, contributor-tier-trial 636,664 / 33 min, both under 1,200,000, no size up; 2 parts, no split.
- Retro (T1): sprint-19-records note 5 to Pool 21, note 6 (bench 3,513 output tokens, 5 calls, 10%, docs-only diff) to Pool 26.
- Trial (T1): quality-first-pass edits the quality review, a measure of the mid-tier keep rule (baseline quality 98/176); the verdict at 6 deliveries notes it.
- Split (T1, size rule): `check-runner-safety` keeps the toolchain-write part's 3 headings; the runner's 4 in Pool 4.
- New defect (T1, note 13 item 1): `sprint-count-t0` in Pool 3; Sprint 20 may close early until it lands.
