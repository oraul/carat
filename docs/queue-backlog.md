# Queue: backlog

Ordered by `docs/goals.md`; folded findings are in `docs/backlog.md`. Every fix is accepted with `lh` 26.0, `j` 27.0, `insert` 26.0 held.

## Sprint 12

1. `windows-buffers-tidy` (T6 with a security Low (4), estimated medium, backlog-pick batch 2; lines at 68eb750): `:ls` and E162 print a newline in a file name as a line break, forging lines (`carat/use_cases/buffers/list_buffers.rb:72`, `carat/domain/messages.rb:16`); five methods walk every window of every tab (`carat/domain/tab_list.rb:128`, `:145`, `:164`, `:229`, `carat/domain/buffer_list.rb:308`); DeleteBuffer, ListBuffers, CloseOtherWindows reach TabList through `BufferList#tabs` (`delete_buffer.rb:31`, `list_buffers.rb:56`, `:73`, `close_other_windows.rb:26`) while their siblings take `tabs:`; stale comments (`close_tab.rb:8`, `close_other_tabs.rb:8`, `window_requests.rb:124`, `layout_node.rb:8`, `buffer.rb:145`) and an 83-column line (`carat/use_cases/windows/scroll_request.rb:5`). Accepted when `test/editor_buffers.rb` shows a newline name escaped in `:ls` and E162, one walk answers the five, `test/adapters_assembly.rb` checks the injected `tabs:`, no comment over its file's width. Backlog: "## :ls and E162 show a newline in a file name as a line break", "## Five methods walk every window of every tab page", "## DeleteBuffer and ListBuffers reach TabList through BufferList", "## Three window closers still say only a modified buffer stays listed", "## Two comments still call the row under a window its status line", "### A rewrapped comment in scroll_request.rb is still 83 columns wide".

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
22. `plan-apply-guard` (T1 pipeline, estimated small): groom took a stale feature queue and folded an absent path. Groom printed 22 headings groomed, the backlog lost 20 (sprint-11-records retro note 10); accepted when a tools-test case counts the two apart. Backlog: "### Records change steps outside groom to fix the queues and docs-lint (quality advisory)".
23. `sprint-marker-tidy` (T1 pipeline advisories, estimated small).
24. `scout-value` (T1 pipeline, estimated small): scout 20.4% at review-pipeline-a, 25.1% at windows-tabs-tidy, 31.5% on ux-fixes-a's resume. Accepted when the next three no-`carat/` changes and resumes past the proposal run no scout, first.check 1.
25. `check-skip` (T1 pipeline, estimated small): check output 22,463 at ux-fixes-a against 2,010 to 6,432 before, first pass 118/120. Accepted when three runs keep it at or under 6,000.
26. `records-trim` (T1 pipeline, estimated small): a records change ran the benchmark (3,791 of 38,845 output, 9.8%) and the quality review (reviews 15,912, 41.0%) with no carat/ change and nothing blocking (sprint-11-records retro notes 8, 9; bench 4,848 at sprint-10-records). Accepted when the next two records changes record no bench phase and reviews at or under 20% of output, the security review kept. Backlog: "### A change touching no carat/, bench/, or test/ file still runs the benchmark phase".
27. `sprint-security`, `content-gate-gaps` (pushed back 15) (T1 security, Medium (7), estimated medium each).
28. `ci-scope-quoting` (T1 pipeline, Low (6), estimated medium, pushed back 3).
29. `open-pr-refusals` (T1 security Lows, estimated medium, pushed back 3).
30. `run-resume` (T1 pipeline, estimated medium, pushed back 17).
31. `check-runner-safety` (T1 security, Medium (6), estimated medium, pushed back 15).
32. `ci-hardening` (T3 with T6, estimated medium, pushed back 23): sweep Low (6).
33. `file-access-tidy` (T4 with T6, estimated medium, pushed back 26).
34. `architecture-docs` (T6, estimated small, pushed back 1): sweep notes 17, 24 to 29, 69; `docs/architecture.md:213`.
35. `periodic-blockers-b`, `ex-handlers-tidy`, `plugin-host-tidy`, `input-core-tidy`, `ui-code-tidy`, `tools-docs-tidy` (T6, estimated medium each, pushed back up to 8).
36. `editing-counts`, `hover-tidy`, `signature-tidy`, `slots-tidy`, `completion-tidy`, `completion-docs-tidy`, `buffer-list-tidy`, `definitions-tidy` (T6, estimated medium each, pushed back 11 to 16).
37. `core-correctness-b`, `editing-dedup-b` (T6, estimated small each); `editing-dedup-a` (T6, estimated medium).
38. `docs-index` (T6, estimated medium, pushed back 21, split at its start).

## Decisions

- Security first clear (T0): no periodic review in pending sprint-11-records; sprint-11 Medium (4), Low (3) under 8, none disputed.
- `checks-and-pr-lows` (T1 pipeline defect, Lows (3) to (5)) delivered whole: 5 parts, the comma parse and the merger's format being one checks string, so 4 fixes, within goals' about four; no `tools/rules.sh` edit.
- Estimate medium: last 10 backlog rows 639,673 to 1,739,169 total, 24 to 100 min; T1 pipeline rows parallel-lanes 1,072,940/63, review-pipeline-a 765,652/32.
- Removed at delivery; `windows-buffers-tidy` (T6, Low (4)) stays Sprint 12 item 1; feature lane untouched.
- Retro notes 8, 9 (sprint-11-records, bench 9.8%, reviews 41.0% of output) to new `records-trim` (T1, small), pool 26 beside `check-skip`; note 8 repeats a backlog entry, listed by heading.
- Retro note 10 (groom 22 against 20 removed) to `plan-apply-guard` (T1).
- Sprint-11-records quality advisories 1 to 7 handled already; left to the sprint planner.
