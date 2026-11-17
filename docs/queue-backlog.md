# Queue: backlog

Ordered by `docs/goals.md`; folded findings are in `docs/backlog.md`. Every fix is accepted with `lh` 26.0, `j` 27.0, `insert` 26.0 held.

## Sprint 13

1. `sprint-security` (T1 pipeline defect, security Medium (7), Lows (6), (5), estimated medium, backlog-pick batch 1, pushed back 15): a sprint whose security review is not-run or partial, or whose sweep failed to start, is still planned and closed (`.claude/workflows/sprint-planning.js:121`, `:105`; `groom`, `tools/run_state.sh:1389`), so the missed review never runs; the sprint security reviewer records nothing, its findings reaching the run state only through the skeptic, so a capped skeptic leaves a blocking finding unnoted (`sprint-planning.js:113`); `mergeSecurity` drops a differently spelled unreviewed file and records pass (`:97`); the report hides a partial review (`:177`); `listed` checks no sprint membership and `fixed` takes any ancestor, even the root commit (`run_state.sh:1358`, `:1361`). Accepted when tools-test cases show groom and review-due refusing to close a sprint whose security review is partial or not-run, each security finding recorded without the skeptic, a `./`-spelled unreviewed file kept, the report naming a partial review, and `listed` and `fixed` refusing an unproven removal. Backlog: "### Sprint planned and closed without its security review (`sprint-planning` security Medium (7))", "### Sprint security findings reach the run state only through the skeptic (`sprint-planning` security Medium (7))", "### Groom removes security entries without proof of a fix (`sprint-planning` security Low (6))", "### Sprint security continuation drops differently spelled unreviewed files (`sprint-planning` security Low (5))", "### Groom's fixed check accepts any ancestor commit (`sprint-planning` quality advisory)", "### Sprint report hides a partial security review (`sprint-planning` quality advisory)".
2. `git-signs-transport` (T3 security Low (5), Medium (4) below 8, with a blocking T6 correctness fix, estimated medium, backlog-pick batch 2): under a trusted root a partial clone's repo-local `uploadpack` or `core.sshCommand` runs on a lazy fetch where git is older than 2.44, since BRANCH and COUNTS disable only the ext transport (`carat/plugins/git_signs/plugin.rb:27`, `:28`, `:42`; `carat/use_cases/plugins/file_requests.rb:30`), the guard words spelled three times; `head_lines` strips only LF while `Buffer.from_text` drops CR LF (`plugin.rb:253`, `carat/domain/buffer.rb:382`), so every line of an unedited CR LF file gets the changed sign (sprint-12 blocking note 2). Accepted when the promisor scenario of `test/editor_git_signs.rb` shows every transport off whatever the git version, one place holds the guards, and a CR LF row shows no sign on an unedited file. Backlog: "### git_signs relies on GIT_NO_LAZY_FETCH, which a git older than 2.44 ignores (security Low, confidence 5)", "### git_signs disables only the ext transport, so a lazy fetch can run a command", "### BRANCH and COUNTS repeat git_signs' safety arguments".

## Pool

1. `toolchain-clean-scope` (T1 pipeline defect, data loss, estimated small): `Makefile:203` deletes every lane worktree under `tmp` (sweep blocking note 38). Accepted when toolchain-clean removes only SPINEL_SRC and PREFIX. Backlog: "### toolchain-clean deletes every lane worktree under tmp".
2. `secret-patterns` (T1 pipeline security, estimated small, merge-gate rules, alone): `tools/rules.sh` ASSIGN_RE, TOKEN_RE. Backlog: "## The secret patterns miss unquoted assignments and unlisted token shapes".
3. `merge-record-check` (T1 pipeline defect, estimated small): 3 of 6 backlog merges (#161, #162, #166) recorded a wrong CI or merge head. Accepted when tools-test refuses a CI head not the pushed head, or a merged commit not on main.
4. `ruby-structure-remove` (T2 user request, estimated medium, pushed back 3, first of the next backlog sprint by aging): #147 took a 100,000-line open from 22 to 116 ms. Backlog: #147's 7 entries (sprint-9).
5. `spinel-notice` (T2 user request, estimated medium, beyond the sprint by the user): "### Spinel's MIT notice does not travel with the vendored generated header (README.md:212)".
6. `content-gate-gaps` (T1 security Lows (5) to (3), estimated medium, pushed back 15): batch 1's other 4: "## A security review stays current after later instruction-file commits", "## pr-on-push security Low at tools/open_pr.sh:118", "## pr-on-push security Low at .github/workflows/open-pr.yml:39", "## Security Lows of the periodic review at 186ddfb".
7. `lane-guards` (T1 pipeline security, defect, estimated medium): checks-and-pr-lows Lows (5), (4), (4), (3) (sprint-12 Low (5) `deliver-change.js:511` the same); sprint-10 Low (5) `run_state.sh:2350`.
8. `lane-records` (T1 pipeline defect, estimated small): sprint-10 note 1 (`run_state.sh:1708`); "### plan-apply and history write into whatever checkout runs them".
9. `review-pipeline-b` (T1 pipeline, estimated medium): #166 reviews 83,029 of 235,968 output (35.2%). "## The review continuations run one after the other".
10. `git-signs-correctness` (T6 correctness, estimated medium, split at its start): sprint-12 notes 3 to 7; git-signs-status-b's 4 findings, "### git_signs counts stay stale after a fetch", "### git_signs shows no signs for a file committed empty".
11. `windows-buffers-walk` (T6 performance, estimated small): `tab_list.rb:168`, `:186`, `:205`, `:284`, `buffer_list.rb:407`. "## Five methods walk every window of every tab page".
12. `buffer-commands-tidy` (T6, estimated small): `:b 0000000001` E86; "### Three ex handlers spell digits? apart", "### The :e and :w messages still print a newline in a file name as a line break".
13. `lsp-sync-fixes` (T6 correctness, estimated medium, split at its start): `json_rpc_language_gateway.rb:1331`; "### The gateway's six cancel wrappers share one body".
14. `process-capture-hardening` (T3 security Lows, estimated medium, pushed back 1): `process_runner.rb:98` Low (5), `plugin_host.rb:110` Low (3).
15. `ci-hardening` (T3 with T6, estimated medium, pushed back 23): "### CI checkout keeps GITHUB_TOKEN while pull request targets run", "### Workflow actions are pinned by movable tags".
16. `tools-fail-open` (T1 pipeline defect, estimated medium): "### Scanner errors pass the text gates", "### metrics.sh compare passes a base name never measured", "### gate_pushes passes a non-numeric count", "### ci_scope.sh splits changed paths at whitespace".
17. `merge-gate-integrity` (T1 pipeline defect, estimated medium, pushed back 14): merge over 12 calls in 8 of 20 lane rows (lsp-container 15, planner-split-rule 14).
18. `scout-value`, `check-skip`, `records-trim`, `budget-prediction`, `plan-apply-guard`, `run-resume` (T1 pipeline, estimated small each, pushed back up to 17): lsp-container scout 25.9% of output.
19. `review-demotion`, `hook-one-place`, `gate-object-pin`, `own-line-advisories`, `prose-grep-cases`, `spec-tests-first`, `ci-workflow-tidy` (T1 pipeline, estimated medium each, pushed back up to 4).
20. `backlog-read-guard`, `record-tier`, `plan-skip`, `sprint-marker-tidy` (T1 pipeline, estimated small each).
21. `open-pr-refusals`, `check-runner-safety` (T1 security, estimated medium each, pushed back 3 and 15); `ci-scope-quoting` (T1, Low (6), estimated medium).
22. `gateway-split-a`, `gateway-split-b`, `frame-painters`, `plugin-api-split`, `language-followers`, `language-ask-port` (T5 architecture, estimated medium each).
23. `file-access-tidy` (T4 with T6, estimated medium, pushed back 26).
24. `architecture-docs` (T6, estimated small): carat.rb, PluginApi 2.7, map drift entries of sprint-12.
25. `plugin-host-tidy` (T6, estimated medium, pushed back 8): batch 2's 7 area-15 tidy entries.
26. `periodic-blockers-b`, `ex-handlers-tidy`, `input-core-tidy`, `ui-code-tidy`, `tools-docs-tidy`, `editing-counts`, `hover-tidy`, `signature-tidy`, `slots-tidy`, `completion-tidy`, `completion-docs-tidy`, `buffer-list-tidy`, `definitions-tidy`, `core-correctness-b`, `editing-dedup-a`, `editing-dedup-b` (T6, estimated medium each, pushed back up to 16).
27. `docs-index` (T6, estimated medium, pushed back 21, split at its start).

## Decisions

- Security first clear (T0): sprint-12 security Low (5) `deliver-change.js:511`, sweep pass high=0 medium=0 low=3 (6, 5, 4); nothing at 8, nothing disputed.
- Sprint 13: 3 features, 2 backlog; the backlog pair is backlog-pick's first two batches after this grooming (area 1, 10 of 471; area 15, 10 of 58).
- Split rule (3 or more parts): batch 1's 6 sprint-planning entries form `sprint-security`, its other 4 go to `content-gate-gaps`; batch 2's git_signs entry with its 2 siblings and blocking note 2 form `git-signs-transport`, 7 tidy entries go to `plugin-host-tidy`, 2 API requests to `plugin-protocol-a`.
- unmapped: 27 headings backlog-pick maps to no area (`## The mouse is not supported (docs/queue.md)` among them), left for `docs-index`.
- Groom: 13 headings the sprint's items listed; "## Five methods walk every window of every tab page" kept, windows-buffers-tidy listed it but left it to `windows-buffers-walk`.
- Duplicate candidate `docs/spinel-notes.md:47` judged distinct (bump procedure against bullet wording); both to `spinel-workarounds`.
- Backlog triage done once already (`git log -S 'Backlog triage:'` prints 9b764e3, b31fcd5).
- Sweep blocking note 38 (`Makefile:203`, data loss) is `toolchain-clean-scope` (T1 defect), pool 1 for sprint 14.
- Estimate medium for both: T1 backlog rows 765,652 to 1,099,021 total; checks-and-pr-lows 235,968 output with rework 3.
- Sprint-12 quality first pass 3 of 6 (checks-and-pr-lows, git-signs-status-b, markdown-reading-c 0; rework 3, 1, 3).
- Retro notes lsp-container 5 to 7 and planner-split-rule 5 to 7 fold into `merge-gate-integrity`, `scout-value`, `lane-records`; their headings are in lsp-container's findings.
- Sweep tooling notes 4, 41, 42, 48 form `tools-fail-open` (T1 defect, fail-open gates); 51 other sweep notes go to `build/plan/groomed.md`.
