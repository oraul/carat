# Queue: backlog

Ordered by `docs/goals.md`; folded findings are in `docs/backlog.md`. Every fix is accepted with `lh` 26.0, `j` 27.0, `insert` 26.0 held.

## Sprint 12

1. `checks-and-pr-lows` (T1 pipeline defect, security Lows (3) to (5), estimated medium, backlog-pick batch 1): late-finding notes reach `docs/backlog.md` verbatim (`tools/run_state.sh:1657`, `:1670`), writable by branch code the checks run (Low (3)); the head checkout keeps persist-credentials true (`.github/workflows/open-pr.yml:46`, Low (4)); `wait` records the highest pull request whose `refs/pull/*/head` equals the pushed sha (`tools/open_pr.sh:126`), so a fork's on the same commit wins (Low (5), raised at the removed pr_tag.sh); `staleRed` splits a check on every comma (`.claude/workflows/deliver-change.js:367`), misreading `spin (ubuntu, 4)`; `.claude/agents/merger.md:24` returns checks as `workflow, name, status, conclusion` but pending ones as `name: status, conclusion`, the workflow field with no stated source. Accepted when tools-test cases show a note not written by the workflow kept out of the history, the head checkout storing no token, a fork's pull request on the pushed sha not recorded, a comma name parsed, one checks format. Backlog: "## delivery-speed security Low (3) at tools/run_state.sh:1215", "## pr-by-tag security Low at .github/workflows/open-pr.yml:36", "## pr-by-tag security Low at tools/pr_tag.sh:121", "## delivery-speed quality advisory at .claude/workflows/deliver-change.js:301", "### The merger's checks list has no stated source for each check's workflow", "### The merger returns checks in two shapes".
2. `windows-buffers-tidy` (T6 with a security Low (4), estimated medium, backlog-pick batch 2; lines at 68eb750): `:ls` and E162 print a newline in a file name as a line break, forging lines (`carat/use_cases/buffers/list_buffers.rb:72`, `carat/domain/messages.rb:16`); five methods walk every window of every tab (`carat/domain/tab_list.rb:128`, `:145`, `:164`, `:229`, `carat/domain/buffer_list.rb:308`); DeleteBuffer, ListBuffers, CloseOtherWindows reach TabList through `BufferList#tabs` (`delete_buffer.rb:31`, `list_buffers.rb:56`, `:73`, `close_other_windows.rb:26`) while their siblings take `tabs:`; stale comments (`close_tab.rb:8`, `close_other_tabs.rb:8`, `window_requests.rb:124`, `layout_node.rb:8`, `buffer.rb:145`) and an 83-column line (`carat/use_cases/windows/scroll_request.rb:5`). Accepted when `test/editor_buffers.rb` shows a newline name escaped in `:ls` and E162, one walk answers the five, `test/adapters_assembly.rb` checks the injected `tabs:`, no comment over its file's width. Backlog: "## :ls and E162 show a newline in a file name as a line break", "## Five methods walk every window of every tab page", "## DeleteBuffer and ListBuffers reach TabList through BufferList", "## Three window closers still say only a modified buffer stays listed", "## Two comments still call the row under a window its status line", "### A rewrapped comment in scroll_request.rb is still 83 columns wide".

## Pool

1. `secret-patterns` (T1 pipeline security, estimated small, merge-gate rules, alone): `tools/rules.sh` ASSIGN_RE, TOKEN_RE. Backlog: "## The secret patterns miss unquoted assignments and unlisted token shapes".
2. `ruby-structure-remove` (T2 user request, fix, estimated medium, pushed back 2, S12): #147's check took a 100,000-line open from 22 to 116 ms; remove it. Backlog: the 7 entries #147 left (sprint-9).
3. `git-signs-transport` (T3 security Medium (4), estimated small): only `protocol.ext.allow=never` guards BRANCH and COUNTS (`carat/plugins/git_signs/plugin.rb:27`, `:28`), so a trusted root's partial clone with a repo-local `uploadpack` or `core.sshCommand` runs a command on a lazy fetch where git is older than 2.44 (`file_requests.rb:30`). Accepted when the promisor scenario of `test/editor_git_signs.rb` shows every transport off whatever the git version. Backlog: "### git_signs disables only the ext transport, so a lazy fetch can run a command", "### BRANCH and COUNTS repeat git_signs' safety arguments".
4. `spinel-notice` (T2 user request, estimated medium, beyond the sprint by the user). Backlog: "### Spinel's MIT notice does not travel with the vendored generated header (README.md:212)".
5. `lane-guards` (T1 pipeline security, defect, estimated medium): sprint-10 Low (5) `run_state.sh:2350`; parallel-lanes-b Medium (5), Lows (4), (3); sweep note 37.
6. `lane-records` (T1 pipeline defect, estimated small): sprint-10 note 1 (`run_state.sh:1708`); sweep notes 15, 16, 38.
7. `merge-record-check` (T1 pipeline defect, estimated small): 2 of the last 3 runs (#161, #162) recorded wrong CI or merge heads; accepted when tools-test refuses a CI head not the pushed head, or a merged commit not on main.
8. `planner-split-rule` (T1 pipeline defect, estimated small, pushed back 1): 4-part briefs used 3 rounds.
9. `review-pipeline-b` (T1 pipeline, estimated medium). Backlog: "## The review continuations run one after the other", "## A security review after a quality-only fix reads the whole branch again".
10. `lsp-sync-fixes` (T6 correctness, estimated medium, split at its start): sweep notes 23, 32; lsp-incremental-sync findings; the diff inside the 1438-line gateway (`json_rpc_language_gateway.rb:1331`), its UTF-8 test written three times (`:1377`, `:1074`, `:1119`). Backlog: "### The incremental-sync text diff lives in the 1438-line gateway", "### The gateway repeats the UTF-8 continuation-byte test".
11. `buffer-commands-tidy` (T6 correctness, estimated small): `:b 0000000001` answers E86 (`buffer_command_handler.rb:97`); `digits?` twice (`:102`, `history_command_handler.rb:67`); `:current` only returns `Outcome.none` (`buffer_request.rb:7`). Backlog: "## BufferCommandHandler#digits? duplicates HistoryCommandHandler.digits?", "## A buffer number with leading zeros past nine bytes reads as the largest", "## BufferRequest's :current target exists only to return no outcome".
12. `ci-workflow-tidy` (T1 pipeline defect, estimated medium, split at its start): `main.yml:47`.
13. `process-capture-hardening` (T3 security Lows, estimated medium, pushed back 1, S12): a relative PATH entry runs a project's `./git` (`process_runner.rb:98`, Low (5)); trust decided once (`plugin_host.rb:110`, Low (3)). Backlog: "### Relative PATH entries let git_signs run a project's ./git", "### PluginHost decides run_program trust once at activation", "### Three comments wrap past 72 columns in file_requests.rb and the gateway", sprint-9's 4 capture entries.
14. `gateway-split-a`, `gateway-split-b`, `frame-painters`, `plugin-api-split` (S12, pushed back 1), `language-followers` (S13), `language-ask-port` (S15) (T5 architecture review, estimated medium each).
15. `backlog-read-guard`, `record-tier`, `plan-skip` (T1 pipeline, estimated small each).
16. `gate-object-pin` (T1 pipeline security, estimated medium, pushed back 3: Medium (5), (6), below 8).
17. `own-line-advisories`, `prose-grep-cases`, `spec-tests-first` (T1 pipeline, estimated medium each).
18. `hook-one-place` (T1 pipeline, estimated medium, pushed back 2, S12).
19. `merge-gate-integrity` (T1 pipeline defect, estimated medium, pushed back 14, S13): merge over 12 calls in 5 of 11 backlog runs (windows-tabs-tidy 14, 27,782 output). Backlog: "### The close start returned a placeholder with no tool calls".
20. `review-demotion` (T1 pipeline defect, estimated medium, pushed back 4, S15): reviews 21.9% to 36.6% of output.
21. `budget-prediction` (T1 pipeline, estimated small): 12.2 total per output token at sprint-10-records; windows-tabs-tidy check 240,137 output against 200,000. Accepted when the check-pass line predicts right for five runs.
22. `plan-apply-guard` (T1 pipeline, estimated small): groom took a stale feature queue and folded an absent path. Backlog: "### Records change steps outside groom to fix the queues and docs-lint (quality advisory)".
23. `sprint-marker-tidy` (T1 pipeline advisories, estimated small).
24. `scout-value` (T1 pipeline, estimated small): scout 20.4% at review-pipeline-a, 25.1% at windows-tabs-tidy, 31.5% on ux-fixes-a's resume. Accepted when the next three no-`carat/` changes and resumes past the proposal run no scout, first.check 1.
25. `check-skip` (T1 pipeline, estimated small): check output 22,463 at ux-fixes-a against 2,010 to 6,432 before, first pass 118/120. Accepted when three runs keep it at or under 6,000.
26. `sprint-security`, `content-gate-gaps` (pushed back 15) (T1 security, Medium (7), estimated medium each).
27. `ci-scope-quoting` (T1 pipeline, Low (6), estimated medium, pushed back 3).
28. `open-pr-refusals` (T1 security Lows, estimated medium, pushed back 3).
29. `run-resume` (T1 pipeline, estimated medium, pushed back 17).
30. `check-runner-safety` (T1 security, Medium (6), estimated medium, pushed back 15).
31. `ci-hardening` (T3 with T6, estimated medium, pushed back 23): sweep Low (6).
32. `file-access-tidy` (T4 with T6, estimated medium, pushed back 26).
33. `architecture-docs` (T6, estimated small, pushed back 1): sweep notes 17, 24 to 29, 69; `docs/architecture.md:213`.
34. `periodic-blockers-b`, `ex-handlers-tidy`, `plugin-host-tidy`, `input-core-tidy`, `ui-code-tidy`, `tools-docs-tidy` (T6, estimated medium each, pushed back up to 8).
35. `editing-counts`, `hover-tidy`, `signature-tidy`, `slots-tidy`, `completion-tidy`, `completion-docs-tidy`, `buffer-list-tidy`, `definitions-tidy` (T6, estimated medium each, pushed back 11 to 16).
36. `core-correctness-b`, `editing-dedup-b` (T6, estimated small each); `editing-dedup-a` (T6, estimated medium).
37. `docs-index` (T6, estimated medium, pushed back 21, split at its start).

## Decisions

- Security first clear (T0): sprint-11 security Medium (4) and Low (3) under 8, none disputed; `git-signs-transport` (T3) placed pool 3.
- Sprint 12: 3 features, 2 backlog: backlog-pick batches 1 and 2, each named by every location (windows-tabs-tidy retro note 6).
- Batch 1 (T1 pipeline defect): 5 of its 10 headings listed by `review-pipeline-a`; `gates.sh:112` entry left to `content-gate-gaps` (merge-gate rule, alone); the 186ddfb entry stays with `ci-hardening`, `bidi-controls`, `file-access-tidy`.
- Batch 2 (T6, Low (4)): 5 of its 10 headings listed by `windows-tabs-tidy`; folds the 83-column line (sprint-11 note 9).
- 23 `unmapped:` pick headings (no map area) stay in the backlog.
- Push-backs: S12 `ruby-structure-remove` to 2, `process-capture-hardening`, `plugin-api-split` to 1, `hook-one-place` to 2.
- Sprint-11 quality notes 5, 6 to `lsp-sync-fixes` (now medium, 6 parts); notes 2, 8, 10 to `process-capture-hardening`; note 11 to batch 1.
- Retro notes: ux-fixes-a 6 to `check-skip`, 7 and windows-tabs-tidy 5 to `scout-value`, windows-tabs-tidy 4 to `budget-prediction`, 7 and 8 to `merge-gate-integrity`.
- Calibration: last 10 backlog rows 639,673 to 1,739,169 total, 24 to 100 min, quality 5/10, feature 775,758 to 1,284,000, 51 to 169, 6/10: no change.
- Triage done (b31fcd5); 4 `spinel-notes.md:47` entries merged, 2 repeated headings dropped.
