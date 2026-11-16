# Queue: backlog

Ordered by `docs/goals.md`; folded findings are in `docs/backlog.md`. Every fix is accepted with `lh` 26.0, `j` 27.0, `insert` 32.0 held.

## Sprint 11

1. `review-pipeline-a` (T1 pipeline defect, security Lows, estimated medium, backlog-pick batch 1): the `guard and gates` pattern (`tools/run_state.sh:161`) leaves out `run_state.sh` and `deliver-change.js`, whose records `gates.sh` trusts (Low (7)); staleRed matches check runs by name, so a branch-added workflow's green job hides a red run (`.claude/workflows/deliver-change.js:301`, Low (4)); `security-reviewer.md:33` reverses the not-run order; `missedOf` (`periodic-review.js:85`) takes either kind's values; the continued prompt joins its sentence to the last file (`deliver-change.js:586`). Accepted when tools-test cases show both files reviewed, another workflow's green run not clearing a red one, missedOf refusing the other kind, the last path alone. Backlog: "## The guard and gates review area leaves out the review's own record keepers", "## delivery-speed security Low (4) at .claude/workflows/deliver-change.js:301", "## The security reviewer's not-run order reads reversed", "## The periodic review's missed check accepts either kind's values", "## The continued security prompt joins its sentence to the last file left".
2. `windows-tabs-tidy` (T6 with a security Low (4), estimated medium, backlog-pick batch 2): `offset_refusal` (`carat/domain/float_spec.rb:58`) uses Integer#abs, failing at the integer minimum; `scroll_handler.rb:20` writes a trait after super, `:33` names half-page targets twice; `tab_request.rb:13` counted? and `command_grammar.rb:84` operator_pending? unused; digits? twice (`buffer_command_handler.rb:98`, `history_command_handler.rb:65`); `:b 0000000001` gives E86 (`buffer_command_handler.rb:92`); `buffer_request.rb:5` `:current` does nothing; `close_other_windows.rb:34` clears previous twice; 9 comments over their wrap (`scroll_window.rb:18`). Accepted when tests show the minimum offset refused, `:b 0000000001` on buffer 1, one digits?, allocations held. Backlog: "## Float offset check overflows at the integer minimum (float-placement, security Low (4))", "## ScrollHandler sets a base class trait after super", "## Half-page scroll targets have two names", "## Nine comments break their file's wrap width", "## TabRequest#counted? and CommandGrammar#operator_pending? have no caller", "## BufferCommandHandler#digits? duplicates HistoryCommandHandler.digits?", "## A buffer number with leading zeros past nine bytes reads as the largest", "## BufferRequest's :current target exists only to return no outcome", "## CloseOtherWindows clears tab.previous a second time".

## Pool

1. `secret-patterns` (T1 pipeline security, estimated small, merge-gate rules, alone): `tools/rules.sh` ASSIGN_RE, TOKEN_RE. Backlog: "## The secret patterns miss unquoted assignments and unlisted token shapes".
2. `ruby-structure-remove` (T2 user request, fix, estimated medium, pushed back 1, S12): #147's check took a 100,000-line open from 22 to 116 ms; remove it, highlighting unchanged. Backlog: the 7 Ruby structure, filetype-table, tokenizer, and README-wording entries #147 left (sprint-9).
3. `spinel-notice` (T2 user request, docs, estimated medium, beyond the sprint by the user): Backlog: "### Spinel's MIT notice does not travel with the vendored generated header (README.md:212)".
4. `lane-guards` (T1 pipeline security, defect, estimated medium): sprint-10 Low (5) `run_state.sh:2350`; parallel-lanes-b Medium (5), Low (4), Low (3); sweep note 37.
5. `lane-records` (T1 pipeline defect, estimated small): sprint-10 note 1 (`run_state.sh:1708`); sweep notes 15, 16, 38.
6. `planner-split-rule` (T1 pipeline defect, estimated small, pushed back 1): 4-part briefs used 3 rounds.
7. `review-pipeline-b` (T1 pipeline, estimated medium): Backlog: "## The review continuations run one after the other", "## A security review after a quality-only fix reads the whole branch again".
8. `lsp-sync-fixes` (T6 correctness, estimated small): sweep notes 23, 32; lsp-incremental-sync findings.
9. `ci-workflow-tidy` (T1 pipeline defect, estimated medium, split at its start): `main.yml:47`.
10. `gateway-split-a` (T5 architecture-review M1, estimated medium, pushed back 1).
11. `backlog-read-guard` (T1 pipeline, estimated small, pushed back 1).
12. `gate-object-pin` (T1 pipeline security, estimated medium, pushed back 3, reason: Medium (5), (6), below 8).
13. `frame-painters` (T5 architecture-review M2, estimated medium).
14. `own-line-advisories` (T1 pipeline, estimated medium).
15. `gateway-split-b` (T5 architecture-review M1, estimated medium).
16. `process-capture-hardening` (T3 security Lows, estimated medium, S12): Backlog: "### Relative PATH entries let git_signs run a project's ./git".
17. `hook-one-place` (T1 pipeline, estimated medium, pushed back 1, S12).
18. `plugin-api-split` (T5 architecture-review M3, estimated medium, S12).
19. `merge-gate-integrity` (T1 pipeline defect, estimated medium, pushed back 14, S13): merge 12+ calls in 10 of 12 runs. Backlog: "### The close start returned a placeholder with no tool calls".
20. `language-followers` (T5 architecture-review H2, estimated medium, S13).
21. `review-demotion` (T1 pipeline defect, estimated medium, pushed back 4, S15): reviews 21.9% to 36.6% of output.
22. `record-tier` (T1 pipeline, estimated small).
23. `prose-grep-cases` (T1 pipeline, estimated medium).
24. `plan-apply-guard` (T1 pipeline, estimated small).
25. `sprint-marker-tidy` (T1 pipeline advisories, estimated small).
26. `plan-skip` (T1 pipeline, estimated small): plan in 10 of 10 rows.
27. `scout-value` (T1 pipeline, estimated small): scout 15.6% of output.
28. `check-skip` (T1 pipeline, estimated small): check first pass 113 of 115.
29. `language-ask-port` (T5 architecture-review H1, estimated medium, S15).
30. `sprint-security` (T1 pipeline security, estimated medium, pushed back 3): Medium (7).
31. `content-gate-gaps` (T1 security, estimated medium, pushed back 15): Medium (7).
32. `ci-scope-quoting` (T1 pipeline, Low (6), estimated medium, pushed back 3).
33. `spec-tests-first` (T1 pipeline, estimated medium, pushed back 3).
34. `open-pr-refusals` (T1 security Lows, estimated medium, pushed back 3).
35. `run-resume` (T1 pipeline, estimated medium, pushed back 17).
36. `check-runner-safety` (T1 security, estimated medium, pushed back 15): Medium (6); sweep note 6.
37. `ci-hardening` (T3 with T6, estimated medium, pushed back 23): sweep Low (6).
38. `file-access-tidy` (T4 with T6, estimated medium, pushed back 26).
39. `architecture-docs` (T6, estimated small, pushed back 1): sweep notes 17, 24 to 29, 69.
40. `periodic-blockers-b` (T6, estimated medium, pushed back 8).
41. `ex-handlers-tidy` (T6, estimated medium): sweep notes 21, 22.
42. `editing-counts`, `hover-tidy`, `signature-tidy`, `slots-tidy` (T6, estimated medium each, pushed back 11 to 13).
43. `completion-tidy`, `completion-docs-tidy`, `buffer-list-tidy`, `definitions-tidy` (T6, estimated medium each, pushed back 11 to 16).
44. `plugin-host-tidy` (T6, estimated medium, pushed back 1).
45. `input-core-tidy` (T6, estimated medium, pushed back 1): sweep notes 8 to 11.
46. `core-correctness-b` (T6, estimated small): sweep notes 4, 7, 46, 50, 51.
47. `editing-dedup-a` (T6, estimated medium): sweep notes 42 to 44, 53, 55.
48. `editing-dedup-b` (T6, estimated small).
49. `ui-code-tidy` (T6, estimated medium, pushed back 1): sweep notes 59 to 63, 66 to 68.
50. `tools-docs-tidy` (T6, estimated medium, pushed back 1): sweep notes 14, 35.
51. `docs-index` (T6, estimated medium, pushed back 21, split at its start).

## Decisions

- Sprint 11: 3 features, 2 backlog: backlog-pick batches 1 (area 1, 10 of 451) and 2 (area 11, 10 of 57); `review-pipeline-a` the one pipeline item, a defect (Lows (7), (4)).
- Batch 1 split, 10 to 5 by the size check: rules.sh to `secret-patterns` (merge-gate rules alone), 2 to `review-pipeline-b`, Lows at 186ddfb and `gates.sh:112` kept by `ci-hardening`, `content-gate-gaps`.
- Batch 2: 9 of 10, `:g`'s `:m :t :normal` to the feature pool. Unmapped: 24 headings (README, CLAUDE.md, docs/queue.md) to `architecture-docs`, `docs-index`.
- `ruby-structure-remove` (T2) and `planner-split-rule` pushed back 1 by the batch rule.
- Backlog triage: 3 stale (`fixed` 9aeb13f, f26b539): 4 entries name only deleted files, 2 still hold.
- Groom: 2 `listed` by markdown-reading-b; backlog-dups 2 groups, 0 duplicates.
- Sprint-10: 70 sweep and 10 review notes: 40 entries to `groomed.md`, 1 queued T0, 32 duplicates of entries or pool items.
- Retro notes: lsp-incremental-sync 9, markdown-reading-b 8 to `review-demotion`; note 10 (check 24,171 output) to `check-skip`; markdown-reading-b 7 to `scout-value`; 6 (merge 30,050/12) and overrun (14 calls, cap 12) to `merge-gate-integrity`.
- Calibrate: backlog 5 rows since the split, 1,171,692 mean total, 70.8 min, quality 0/5, 0 entries closed; feature 930,246, 80.6 min, quality 3/5; no budget change until 3 batch runs close entries.
- Security first resolved: sweep High (9) `git_signs/plugin.rb:23` at f26b539 is fixed by f29f956 (#160, `git-signs-trust`, its review security pass high=0 at 283ab0cf503c): trusted-root refusal, `GIT_NO_LAZY_FETCH=1`, `protocol.ext.allow=never`, tested in `test/editor_git_signs.rb`; `sprint-10-records` (T0 records, estimated small) proceeds.
