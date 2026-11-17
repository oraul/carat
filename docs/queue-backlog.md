# Queue: backlog

Ordered by `docs/goals.md`; folded findings are in `docs/backlog.md`. Every fix is accepted with `lh` 26.0, `j` 27.0, `insert` 26.0 held.

## Sprint 12

Backlog lane complete: `checks-and-pr-lows` merged (#166), `windows-buffers-tidy` part a delivered; part b `windows-buffers-walk` waits in the pool.

The user-approved exception: `planner-split-rule` (T1 pipeline defect, user request, estimated small, beyond the sprint, the user-approved exception), Sprint 12's one exemption.

## Pool

1. `secret-patterns` (T1 pipeline security, estimated small, merge-gate rules, alone): `tools/rules.sh` ASSIGN_RE, TOKEN_RE. Backlog: "## The secret patterns miss unquoted assignments and unlisted token shapes".
2. `merge-record-check` (T1 pipeline defect, estimated small): 3 of the last 6 backlog merges (#161, #162, #166) recorded a wrong CI or merge head (#166: phase.ci at the squash, phase.merge and the retrospective's merged commit at the branch head). Accepted when tools-test refuses a CI head not the pushed head, or a phase.merge or retro merged commit not on main or unequal to the run state's `merged`.
3. `ruby-structure-remove` (T2 user request, fix, estimated medium, pushed back 2, S12): #147's check took a 100,000-line open from 22 to 116 ms; remove it. Backlog: the 7 entries #147 left (sprint-9).
4. `git-signs-transport` (T3 security Medium (4), estimated small): only `protocol.ext.allow=never` guards BRANCH and COUNTS (`carat/plugins/git_signs/plugin.rb:27`, `:28`), so a trusted root's partial clone with a repo-local `uploadpack` or `core.sshCommand` runs a command on a lazy fetch where git is older than 2.44 (`file_requests.rb:30`). Accepted when the promisor scenario of `test/editor_git_signs.rb` shows every transport off whatever the git version. Backlog: "### git_signs disables only the ext transport, so a lazy fetch can run a command", "### BRANCH and COUNTS repeat git_signs' safety arguments".
5. `spinel-notice` (T2 user request, estimated medium, beyond the sprint by the user). Backlog: "### Spinel's MIT notice does not travel with the vendored generated header (README.md:212)".
6. `lane-guards` (T1 pipeline security, defect, estimated medium): sprint-10 Low (5) `run_state.sh:2350`; parallel-lanes-b Medium (5), Lows (4), (3); sweep note 37.
7. `lane-records` (T1 pipeline defect, estimated small): sprint-10 note 1 (`run_state.sh:1708`); sweep notes 15, 16, 38.
8. `review-pipeline-b` (T1 pipeline, estimated medium): a rerun after a fix re-reads the whole branch; #166 reviews 83,029 of 235,968 output (35.2%), 6 of 11 quality advisories repeated an earlier note. Accepted when a rerun records no advisory noted at an earlier commit of the run. Backlog: "## The review continuations run one after the other", "## A security review after a quality-only fix reads the whole branch again".
9. `lsp-sync-fixes` (T6 correctness, estimated medium, split at its start): sweep notes 23, 32; lsp-incremental-sync findings; the diff inside the 1438-line gateway (`json_rpc_language_gateway.rb:1331`), its UTF-8 test written three times (`:1377`, `:1074`, `:1119`). Backlog: "### The incremental-sync text diff lives in the 1438-line gateway", "### The gateway repeats the UTF-8 continuation-byte test".
10. `buffer-commands-tidy` (T6 correctness, estimated small): `:b 0000000001` answers E86 (`buffer_command_handler.rb:97`); `digits?` twice (`:102`, `history_command_handler.rb:67`); `:current` only returns `Outcome.none` (`buffer_request.rb:7`). Backlog: "## BufferCommandHandler#digits? duplicates HistoryCommandHandler.digits?", "## A buffer number with leading zeros past nine bytes reads as the largest", "## BufferRequest's :current target exists only to return no outcome".
11. `windows-buffers-walk` (T6 performance, estimated small, part b of windows-buffers-tidy; lines at 98dc43e): `shown?`, `windows_showing`, `focus_buffer`, `modified_in_page` (`carat/domain/tab_list.rb:168`, `:186`, `:205`, `:284`) and `close_windows_of` (`carat/domain/buffer_list.rb:407`) each walk every window of every tab page. Accepted when one walk answers the five, allocations held. Backlog: "## Five methods walk every window of every tab page".
12. `ci-workflow-tidy` (T1 pipeline defect, estimated medium, split at its start): `main.yml:47`.
13. `process-capture-hardening` (T3 security Lows, estimated medium, pushed back 1, S12): a relative PATH entry runs a project's `./git` (`process_runner.rb:98`, Low (5)); trust decided once (`plugin_host.rb:110`, Low (3)). Backlog: "### Relative PATH entries let git_signs run a project's ./git", "### PluginHost decides run_program trust once at activation", "### Three comments wrap past 72 columns in file_requests.rb and the gateway", sprint-9's 4 capture entries.
14. `gateway-split-a`, `gateway-split-b`, `frame-painters`, `plugin-api-split` (S12, pushed back 1), `language-followers` (S13), `language-ask-port` (S15) (T5 architecture review, estimated medium each).
15. `backlog-read-guard`, `record-tier`, `plan-skip` (T1 pipeline, estimated small each).
16. `gate-object-pin` (T1 pipeline security, estimated medium, pushed back 3: Medium (5), (6), below 8).
17. `own-line-advisories`, `prose-grep-cases`, `spec-tests-first` (T1 pipeline, estimated medium each).
18. `hook-one-place` (T1 pipeline, estimated medium, pushed back 2, S12).
19. `merge-gate-integrity` (T1 pipeline defect, estimated medium, pushed back 14, S13): merge over 12 calls in 5 of 11 backlog runs (windows-tabs-tidy 14, 27,782 output; windows-buffers-tidy 14, 17,462 output, 6 CI waits on a first-pass green CI, retro note 8). Backlog: "### The close start returned a placeholder with no tool calls".
20. `review-demotion` (T1 pipeline defect, estimated medium, pushed back 4, S15): reviews 21.9% to 36.6% of output.
21. `budget-prediction` (T1 pipeline, estimated small): 12.2 total per output token at sprint-10-records; windows-tabs-tidy check 240,137 output against 200,000. Accepted when the check-pass line predicts right for five runs.
22. `plan-apply-guard` (T1 pipeline, estimated small): groom took a stale feature queue and folded an absent path. Groom printed 22 headings groomed, the backlog lost 20 (sprint-11-records retro note 10); accepted when a tools-test case counts the two apart. Backlog: "### Records change steps outside groom to fix the queues and docs-lint (quality advisory)".
23. `sprint-marker-tidy` (T1 pipeline advisories, estimated small).
24. `scout-value` (T1 pipeline, estimated small): scout 20.4% at review-pipeline-a, 25.1% at windows-tabs-tidy, 31.5% on ux-fixes-a's resume, 40.1% (45 of 171 calls) on windows-buffers-tidy's (retro note 6). Accepted when the next three no-`carat/` changes and resumes past the proposal run no scout, first.check 1.
25. `check-skip` (T1 pipeline, estimated small): check output 22,463 at ux-fixes-a against 2,010 to 6,432 before, first pass 118/120. Accepted when three runs keep it at or under 6,000.
26. `records-trim` (T1 pipeline, estimated small): a records change ran the benchmark (3,791 of 38,845 output, 9.8%) and the quality review (reviews 15,912, 41.0%) with no carat/ change and nothing blocking (sprint-11-records retro notes 8, 9; bench 4,848 at sprint-10-records). Accepted when the next two records changes record no bench phase and reviews at or under 20% of output, the security review kept. Backlog: "### A change touching no carat/, bench/, or test/ file still runs the benchmark phase".
27. `sprint-security`, `content-gate-gaps` (pushed back 15) (T1 security, Medium (7), estimated medium each).
28. `ci-scope-quoting` (T1 pipeline, Low (6), estimated medium, pushed back 3).
29. `open-pr-refusals` (T1 security Lows, estimated medium, pushed back 3).
30. `run-resume` (T1 pipeline, estimated medium, pushed back 17): a resume re-verifies a finished change, implement 44 calls, 26,671 output (20.8%) on windows-buffers-tidy (retro note 7), the checker then passing first.
31. `check-runner-safety` (T1 security, Medium (6), estimated medium, pushed back 15).
32. `ci-hardening` (T3 with T6, estimated medium, pushed back 23): sweep Low (6).
33. `file-access-tidy` (T4 with T6, estimated medium, pushed back 26).
34. `architecture-docs` (T6, estimated small, pushed back 1): sweep notes 17, 24 to 29, 69; `docs/architecture.md:213`.
35. `periodic-blockers-b`, `ex-handlers-tidy`, `plugin-host-tidy`, `input-core-tidy`, `ui-code-tidy`, `tools-docs-tidy` (T6, estimated medium each, pushed back up to 8).
36. `editing-counts`, `hover-tidy`, `signature-tidy`, `slots-tidy`, `completion-tidy`, `completion-docs-tidy`, `buffer-list-tidy`, `definitions-tidy` (T6, estimated medium each, pushed back 11 to 16).
37. `core-correctness-b`, `editing-dedup-b` (T6, estimated small each); `editing-dedup-a` (T6, estimated medium).
38. `docs-index` (T6, estimated medium, pushed back 21, split at its start).

## Decisions

- Security first clear (T0): windows-buffers-tidy security high=0 medium=0 low=0; no periodic review pending; sprint-11 Medium (4), Low (3) under 8, none disputed.
- `planner-split-rule` (T1 pipeline defect) delivered now as Sprint 12's user-approved exception by the user's "Okay"; pool 8 removed, the sprint's 2 of 2 backlog count unchanged.
- Estimate medium: no non-records backlog row of the last 10 under 741,570 total; T1 rows 765,652/32 to 1,099,021/71; small records 639,673/24, over small's 500k. The exception line keeps the brief's small.
- Size check: 2 parts, within about four, kept together; checks-and-pr-lows (4 fixes) rework 3, quality first pass 0, is the evidence it fixes; no `tools/rules.sh` edit.
- windows-buffers-tidy retro notes 6 (scout 40.1%), 7 (implement 20.8%), 8 (merge 14 calls, 17,462) folded into `scout-value`, `run-resume`, `merge-gate-integrity` (T1).
- git-signs-status-b retro notes 9 to 11 (check 57,747, resumed 0 tokens, quality 62/123) went to markdown-reading-c's findings by its plan; not repeated.
- windows-buffers-tidy quality notes 1 to 5 handled already; feature lane untouched.
