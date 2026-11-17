# Queue: backlog

Ordered by `docs/goals.md`; folded findings are in `docs/backlog.md`. Every fix is accepted with `lh` 26.0, `j` 27.0, `insert` 26.0 held.

## Sprint 15

1. `ci-trust-gaps` (T1 pipeline defect, security Medium (5) below 8 and Lows (6) to (4), estimated medium, backlog-pick batch 1, split at its start): code a branch runs can still steer a gate: CI runs the branch's own scope script, so a branch answering run=false turns the spin check green (`.github/workflows/ci.yml:58`, Low (6)); the check clone shares a writable toolchain (`tools/run_state.sh:571`, Low (5)); a planted loose object substitutes main's gate scripts in the merge gates' worktree (`.claude/workflows/deliver-change.js` mergeLines); the hook pins accept origin's ssh and scp forms (`.claude/agents/merger.md:12`, `deliver-change.js:542` to `:552`, Medium (5)); open-pr counts and edits a fork's same-named pull request with PR_TOKEN (`tools/open_pr.sh:180`, `:190`, `:196`, Lows (5), (4), again in the sprint-14 sweep); the sprint report says the sweep did not run when only its security half did not (`.claude/workflows/sprint-planning.js:179`). Fix outline: each gate reads main's own code and objects and same-repository pull requests only; the report gives the sweep's halves apart. Accepted when tools-test cases show a branch's scope script ignored, a toolchain change by a stage caught, a planted object not reaching the merge gates, an scp-form origin refused, a cross-repository pull request of the same head neither counted nor edited, and the report naming each sweep half. Backlog: "### Restrict the open-pr edit path to same-repository pull requests (security Low, confidence 4)", "### Fork pull requests sharing the branch name block open_pr.sh (security Low (5))", "### The check clone shares a writable toolchain (security Low (5))", "### CI runs the branch's own scope script (security Low (6))", "### The sprint report misreads the sweep", "## Security: a planted git object substitutes content in the merge gates' worktree of origin/main", "### Security: the guard pins accept origin's ssh and scp forms (security Medium (5))".
2. `motions-search-tidy` (T6 with correctness bugs, estimated medium, backlog-pick batch 2, area 6, split at its start): incsearch leaves the cursor past a line end on a $ match (`carat/use_cases/search/preview_search.rb:94`) and spends the full budget on each key (`:48`, about 1.5 s on a costly pattern); sentence motions rescan the whole buffer (`carat/domain/motions.rb:418`, about 96 ms per key on 100,000 lines); ~ in a pattern ignores the last substitute (E33), a second caret reads as an anchor (`carat/domain/vim_pattern.rb:261`), an escaped bracket in a collection cuts the pattern (`vim_pattern.rb:105`); ASCII lines pay the length charge (`carat/domain/search.rb:101`); one-character slices stay quadratic on long UTF-8 lines; motions take the whole EditorState; the pattern cut is written twice (`find_match.rb:68`); the noh row names a test without the case (`docs/compatibility.md:262`); sweep tidy `walker.rb:63`, `motions.rb:599`, `text_objects.rb:86`, `find_match.rb:177`, `test/editor_motions.rb:105`, `vim_pattern.rb:641`, map `docs/codebase-map.md:205`. Fix outline: the correctness bugs first, then the tidy by part. Accepted when rows show the incsearch cursor clamped, a bench row of a sentence motion on 100,000 lines at a tenth of 96 ms, the three patterns as Neovim reads them, and each entry closed or carried to the findings file. Backlog: "## Motions take the whole editor state and write the last find", "## ~ in a search pattern ignores the last substitute", "## Sentence motions rescan the whole buffer on every use", "## Some per-command character loops still slice one-character strings", "## The search budget charges a line's length on ASCII lines too", "## A second caret after the start of a pattern is read as an anchor", "## The search offset is found by a collection scan that differs from the compiler's", "## The :noh row names a test that has no :noh case", "## Incremental search spends the full search budget on every key", "## The pattern-source cut and the prompt prefix are written twice", "### Incremental search leaves the cursor past a line end (sprint-14 sweep quality)", "### Motion code keeps a require cycle, a dead store, and a cls name (sprint-14 sweep quality)", "### Search code copies a class helper and a register loop (sprint-14 sweep quality)", "### Area 6 tests and docs drift (sprint-14 sweep quality)".

## Pool

1. `explorer-tidy` (T6 with a correctness bug, estimated medium, pushed back 1, reason: backlog-pick order): the tree cursor drifts when follow expands above it, and 9 explorer tidy entries.
2. `check-runner-safety` (T1 security, estimated medium, pushed back 16, reason: one pipeline slot, batch 1's): Medium (6) `tools/run_state.sh:639`, Low (4) `:778`.
3. `review-scope-pins` (T1 pipeline, Medium (4), estimated medium, split at its start): unpinned OpenSpec, whole-branch re-review, review cap.
4. `git-signs-transport` (T3 security Low (5), estimated medium, pushed back 3, reason: backlog-pick order): lazy-fetch transports on git before 2.44, the CR LF signs; `git-panel` waits on it.
5. `toolchain-clean-scope` (T1 pipeline defect, data loss, estimated small): `Makefile:203`, `README.md:21`, map area 2.
6. `sprint-security-b` (T1 pipeline defect, security Lows (6) to (3), estimated medium): groom proof, `tools/gates.sh:131` groom_row Low (3) and stripped rows, `run_state.sh:1581` merged_at, merge-record-check's 3 findings.
7. `secret-patterns` (T1 pipeline security, estimated small, merge-gate rules, alone): `tools/rules.sh` ASSIGN_RE, TOKEN_RE.
8. `spinel-notice` (T2 user request, estimated medium): the MIT notice of the vendored header.
9. `content-gate-gaps` (T1 security Lows, estimated medium, pushed back 15).
10. `lane-guards` (T1 pipeline security, estimated medium): `deliver-change.js:511`, `run_state.sh:2350`, `tools/agent_guard.sh:884` pager Low (3).
11. `lane-records` (T1 pipeline defect, estimated small): `run_state.sh:1708`.
12. `review-pipeline-b` (T1 pipeline, estimated medium): reviews 83,029 of 235,968 output; the security record keeps one round (merge-record-check retro 7).
13. `git-signs-correctness` (T6 correctness, estimated medium, split at its start).
14. `windows-buffers-walk` (T6, estimated medium): `tab_list.rb:168`, `buffer_list.rb:407`.
15. `buffer-commands-tidy` (T6, estimated small): E86, digits? copies, newline in names.
16. `lsp-sync-fixes` (T6 correctness, estimated medium, split at its start).
17. `process-capture-hardening` (T3 security Lows, estimated medium, pushed back 1): `process_runner.rb:98`, `plugin_host.rb:110`, `file_requests.rb:141`.
18. `ci-hardening` (T3 with T6, estimated medium, pushed back 24, reason: after `ci-trust-gaps`, the same workflows).
19. `tools-fail-open` (T1 pipeline defect, estimated medium): scanner errors, metrics compare, gate_pushes, ci_scope splits; sweep `gates.sh:333`, `:266`, `open_pr.sh:123`, `metrics.sh:71`.
20. `merge-gate-integrity` (T1 pipeline defect, estimated medium, pushed back 14): merge over 12 calls in 8 of 20 rows; `deliver-change.js:1302`; a refused record drops 30 metric fields.
21. `scout-value`, `check-skip`, `records-trim`, `budget-prediction`, `plan-apply-guard`, `run-resume` (T1 pipeline, estimated small each, pushed back up to 17): scout 21.9% of vim-line-commands-a's output; check 46,390 over 2 passes in merge-record-check.
22. `review-demotion`, `hook-one-place`, `gate-object-pin`, `own-line-advisories`, `prose-grep-cases`, `spec-tests-first`, `ci-workflow-tidy` (T1 pipeline, estimated medium each, pushed back up to 4): advisories dropped 17 of 26 over 5 rows.
23. `backlog-read-guard`, `record-tier`, `plan-skip`, `sprint-marker-tidy` (T1 pipeline, estimated small each): plan 11,391 output kept every decision.
24. `open-pr-refusals` (T1 security, estimated medium, pushed back 3); `ci-scope-quoting` (T1, Low (6), estimated medium).
25. `gateway-split-a`, `gateway-split-b`, `frame-painters`, `plugin-api-split`, `language-followers`, `language-ask-port` (T5 architecture, estimated medium each): UTF-16 walks `json_rpc_language_gateway.rb:1116`.
26. `file-access-tidy` (T4 with T6, estimated medium, pushed back 26): `disk_files.rb:33` Low (3).
27. `architecture-docs` (T6, estimated small): PluginApi 2.8 (`docs/codebase-map.md:535`), carat.rb, map drift.
28. `plugin-host-tidy` (T6, estimated medium, pushed back 8).
29. `periodic-blockers-b`, `ex-handlers-tidy`, `input-core-tidy`, `ui-code-tidy`, `tools-docs-tidy`, `editing-counts`, `hover-tidy`, `signature-tidy`, `slots-tidy`, `completion-tidy`, `completion-docs-tidy`, `buffer-list-tidy`, `definitions-tidy`, `core-correctness-b`, `editing-dedup-a`, `editing-dedup-b` (T6, estimated medium each, pushed back up to 16): bracketed paste Low (5) and `keymap.rb:173` to input-core-tidy, tab_width copies to editing-dedup-a, `gates.sh:86` to tools-docs-tidy.
30. `docs-index` (T6, estimated medium, pushed back 21, split at its start).

## Decisions

- Security first clear (T0): sprint-14 security 1 Low (3) `tools/gates.sh:131`, sweep medium 0 and low 5, 0 disputed; triage done (4 commits).
- 3 features, 2 backlog (T1, T6): backlog-pick batch 1 (area 1, 7 of its 10 left after groom's 3 listed) and batch 2 (area 6, 10 entries plus 4 of the sweep).
- `ci-trust-gaps` the one pipeline item (T1 pipeline defect): Medium (5) and 5 Lows on gate inputs; 6 parts, split at its start; 0 `tools/rules.sh` pattern edits.
- Groom (T1): 7 listed (lsp-container-c 1, markdown-reading-d 3, merge-record-check 3); backlog-dups' one pair on `docs/spinel-notes.md:47` kept, 2 issues.
- Unmapped (T6): backlog-pick's 25 unmapped headings stay in their pool domains.
- `ruby-structure-remove` to the feature lane (T2, pushed back 4): this lane's 2 slots are the batches.
- Sizes medium (T1): last two backlog rows sprint-13-records 1,264,361 over small, tab-close-b 1,050,899 under; merge-record-check 1,087,825 under medium: no size up.
- Retro notes placed (T1): merge-record-check 7 to `review-pipeline-b`, 6 and 8 to `check-skip`, 9 to `merge-gate-integrity`; vim-line-commands-a 4 to `review-demotion`, 5 to `plan-skip`, 6 to `scout-value`.
- Sweep placed (T1, T6): 5 security and 41 quality notes in 25 groomed entries or 5 existing ones.
