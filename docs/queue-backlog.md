# Queue: backlog

Ordered by `docs/goals.md`. Every fix is accepted with `lh` 26.0, `j` 27.0, `insert` 26.0 held.

## Sprint 32

Delivered: `check-jobs-lows` (a985364, #331), `messages-tidy` (628d55e, #332), `render-text-lows` (this delivery); `merge-git-unpin` (e8b9c6e, #334) outside the 3.

## Pool

1. `hand-merge-record` (T1 pipeline defect, estimated small, critical b tools/run_state.sh): lane-guard-lows, hand-merged as 6f0ecc3 (#328), has no `merged` and no history row (its note 3: the squash body's trailer is not exact), so no sprint counts it. Accepted when a tools-test case with a hand merge on main records it and names the trailer problem.
2. `review-record-lows` (T1 pipeline defect, security Low (4), estimated medium, critical a tools/run_state.sh): batch 1's rest: `run_state.sh:1560` squash_commit falls back to HEAD, the security record keeps the last round, the reviewer prompt lacks fixed_in_place, `deliver-change.js:935` carried review, a refused merge on a moved main.
3. `assembly-tidy` (T6, estimated medium, area 4): batch 2's rest: `editor_assembly.rb:723`, `:336`, `:327`, `test/adapters_assembly.rb` labels, `bin/carat.rb:41` leave before stop.
4. `render-tidy-c` (T6, estimated medium, area 13): batch 3's rest: StartArt's 4 headings (`start_art.rb:73`, `:105`, `:130`, `:167`); illegal bytes as hex markers (`decoded_line.rb`).
5. `ex-files-lows` (T6 security Low (5), estimated medium, area 12, critical a carat/use_cases/files/make_path.rb): Sprint 31's, undrawn: `make_path.rb:47`, `ex_range.rb` resolve, `substitute_args.rb:45`, `register_count.rb:38`; its 10 headings in this queue at 6f0ecc3; accepted when `:.,+3s`, `:/foo/d`, `:'a,'bd` rows fail before.
6. `key-input-lows` (T6 security Low (4), estimated medium, area 5, critical a carat/adapters/key_decoder.rb): Sprint 31's, undrawn: `key_decoder.rb:186` early paste end, `handle_key.rb:186` a pasted newline takes the popup's candidate (sweep blocking), 24 allocations per key; its 11 headings at 6f0ecc3.
7. `lane-guard-lows-c` (T1 security Lows (3), estimated medium, critical a .claude/workflows/sprint-planning.js): `sprint-planning.js:293` recordNotes puts finding text in a Bash start's prompt; control characters pass `tools/spec_validate.sh:20` and gateway path_of (`:817`). Accepted when a tools-test case per part and a gateway row fail before. Backlog: "## Security Lows of the periodic review at 186ddfb"; the Notes phase heading (sprint-13 Low (3)) of Pool 1 at 6f0ecc3.
8. `lane-guard-lows-d` (T1 pipeline defect, estimated small, critical b .claude/workflows/deliver-change.js): `deliver-change.js:428` a post-review prose edit refused 1 push (package 21 of 210 calls); `run_state.sh:613` OUTPUT_SHARE 6 against rows of 3.5 to 59. Accepted when a tools-test case per part fails before. Backlog: the prose-edit and budget-line headings (lsp-container-b retro notes 12, 13) of Pool 1 at 6f0ecc3.
9. `risky-config-pager` (T1 security Low (3), estimated small, critical b tools/rules.sh): "### RISKY_CONFIG omits pager keys (sprint-14 sweep security Low (3))", `tools/rules.sh:60` refuses `core.pager`, not `pager.CMD`; this rules.sh edit alone, first.
10. `sprint-29-lows` (T1 security Lows (6), (5), (4), estimated medium, critical a tools/gates.sh): its 6 headings at 9df178c; `tools/gates.sh:662` (sprint-30 Low (6)); sweep note 1 (`agent_guard.sh:707`).
11. `base-figures-trust` (T1 security Low (3), estimated small, critical a tools/run_state.sh): `run_state.sh:2069`; cache-reuse's 2 base-figures headings.
12. `design-drift-sync` (T2 user request, docs, estimated small): `docs/design.md` sections 3 and 7, `themes.rb:244`, `docs/compatibility.md:527`.
13. `cache-reuse-b`, `merge-path-tidy`, `build-tools-lows` (T1, estimated medium each, critical b .claude/workflows/deliver-change.js): prtext into package; merge 51,002 output over 24 calls, CI 12.0 minutes twice.
14. `paste-tidy` (T6, estimated medium, area 5): sweep notes 6 to 11, 2 render-tidy paste headings; `config-trust-tidy` (T3 security Low (4), estimated large, pushed back 3, reason: Lows of untrusted input wait for the user's UI track, critical d carat/domain/config.rb); `plugin-host-tidy-b`, `render-tidy-b`, `recent-files-tidy` (T6, estimated medium each).
15. T1 defects (estimated small each): `check-escape-lane-build`, `main-docs-lint`, `records-timing-escape`, `scan-scheme-host` (critical b tools/scan_text.sh), `ruby-guard`, `quality-rate-frozen`, `stopped-total-unset`, `resume-tokens-id`, `brief-label-cut` (`tools/brief.sh:109` cuts at a label's first occurrence), `merge-main-pin` (`run_state.sh:4370` plain git diff; pushed back 1, reason: the user unpinned merge_main's git, "Remove the pinned git only", 2026-11-23).
16. `pipeline-lows-b` (pushed back 6), `ci-trust-lows`, `tools-bugs`, `quality-tasks-check` (tab-focus-mark retro 4: quality first pass 139/232), `security-advisories-record`, `backlog-per-file-b`, `review-trust-lows-c` (T1, estimated medium each, critical b; reason for push-backs: one guard edit at a time).
17. `skill-guard` (T1, Medium (6), estimated small, pushed back 9, reason: one guard edit at a time, critical a tools/agent_guard.sh); `lane-name-guards`, `groom-findings-refs`, `plan-apply-stale`, `plan-brief-amend`, `plan-cut-first` (T1, estimated small each).
18. Efficiency (T1, estimated small each, pushed back 10, reason: user trims first): `records-bench-skip`, `budget-recalibrate`, `records-queue-lint`, `merge-wait-bound`, `head-drop`, `package-one-start` (package 45,250 and 38,921 output), `nonblocking-round` (lane-guard-lows-b rework 1 on a Low outside its diff), `card-once`, `split-at-placement` (explorer-rows: 280,557 output over 200,000, 49 files, rework 2), `check-scope-skip`, `brief-outcome-only`, `metrics-stage-compare`, `bench-timing-drop`, `check-share` (121,585 of 724,443), `security-zero-cap`, `overrun-once` (explorer-rows: 3 overrun notes in one run, none acted on), `decision-finding-skip` (merge-git-unpin retro 4: a Low that only restates a recorded user decision started a fix round and a close-advisories start; 5 of the last 10 backlog rows rework 1 or more; accepted when such a finding starts neither).
19. `drivers-lsp-lows-b` (T3 Lows, estimated large, pushed back 7, reason: area 17 not picked, critical a carat/drivers/disk_files.rb); `config-guards-c`, `-e`, `-f`, `ex-range-tidy`, `sweep-bugs`, `editing-tidy`, `explorer-sweep`, `cmdline-tidy`, `docs-currency` (T6, estimated medium each).
20. `plugin-api-requests` (T5, estimated large); `plugin-host-move` (T6, estimated large).

## Decisions

- Security first (T0): none; sprint-31 review 0 findings, none disputed; the Medium (6) entries are under confidence 8.
- 3 features, 3 backlog (T1): backlog-pick batches 1 to 3 after the groom, 64 `unmapped:` left; `check-jobs-lows` the one pipeline item, a defect.
- Split (T1): batches of 10 headings, 5 or 6 parts; lows bundles of 8 or more ran 1,907,712 to 2,445,172 total, of 4 to 6 846,123 to 847,871; rests Pool 2 to 4.
- Left out (T1): "### Two lanes share one writable toolchain and compile cache (sprint-10 security Low (3), disputed)" of batch 1 stays disputed; listing it would remove it.
- Groom (T1): 7 fixed (6 at 6f0ecc3, 1 at 6529678), 16 merged (14 backlog-dups pairs, 2 near-same notes); 0 gone of the 50 oldest at HEAD; triage at 8b54500.
- Carried (T6): `ex-files-lows`, `key-input-lows` undrawn in Sprint 31 (the exception filled it): Pool 5, 6.
- Hand merge (T1, user request): lane-guard-lows merged by the user (#328) recorded nowhere: Pool 1.
- Hold (T2 user request, 2026-11-23, "Go this sprint and after on hold"): Sprint 32 runs, then none drawn until lifted.
- Delivered (T3 security Low (6), (3), critical a carat/adapters/line_painter.rb): `render-text-lows`, Sprint 32's last backlog item; medium: 2 testable parts (visible markers, one decoder) plus 3 entries already gone at 6f0ecc3, no split; area 13 rows render-tidy 781,454, plugin-host-lows 846,123; last two lane rows 587,514 and 459,381 under 1.2M, no size-up.
- Placed (T1): merge-git-unpin retro 4, 5 as Pool 18 `decision-finding-skip`; review-in-openspec retro 9 to 11 stay in Pool 18; head-form notes (merge-git-unpin, tab-name-parent) and the reported overrun (review-in-openspec note 12, 1,372,173 against 1.2M) dropped: no decision changes.
