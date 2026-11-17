# Queue: backlog

Ordered by `docs/goals.md`; folded findings are in `docs/backlog.md`. Every fix is accepted with `lh` 26.0, `j` 27.0, `insert` 26.0 held.

## Sprint 13

1. `git-signs-transport` (T3 security Low (5), Medium (4) below 8, with a blocking T6 correctness fix, estimated medium, backlog-pick batch 2): under a trusted root a partial clone's repo-local `uploadpack` or `core.sshCommand` runs on a lazy fetch where git is older than 2.44, since BRANCH and COUNTS disable only the ext transport (`carat/plugins/git_signs/plugin.rb:27`, `:28`, `:42`; `carat/use_cases/plugins/file_requests.rb:30`), the guard words spelled three times; `head_lines` strips only LF while `Buffer.from_text` drops CR LF (`plugin.rb:253`, `carat/domain/buffer.rb:382`), so every line of an unedited CR LF file gets the changed sign (sprint-12 blocking note 2). Accepted when the promisor scenario of `test/editor_git_signs.rb` shows every transport off whatever the git version, one place holds the guards, and a CR LF row shows no sign on an unedited file. Backlog: "### git_signs relies on GIT_NO_LAZY_FETCH, which a git older than 2.44 ignores (security Low, confidence 5)", "### git_signs disables only the ext transport, so a lazy fetch can run a command", "### BRANCH and COUNTS repeat git_signs' safety arguments".

## Pool

1. `toolchain-clean-scope` (T1 pipeline defect, data loss, estimated small): `Makefile:203` deletes every lane worktree under `tmp` (sweep blocking note 38). Accepted when toolchain-clean removes only SPINEL_SRC and PREFIX. Backlog: "### toolchain-clean deletes every lane worktree under tmp".
2. `sprint-security-b` (T1 pipeline defect, security Lows (6), (5), estimated small): part b of `sprint-security`. groom's `listed` checks no sprint membership and `fixed` takes any ancestor, even the root commit (`tools/run_state.sh:1358`, `:1361`), so a security entry leaves without proof of a fix; `mergeSecurity` drops a `./`-spelled unreviewed file and records pass (`.claude/workflows/sprint-planning.js:97`). Accepted when tools-test cases show `listed` and `fixed` refusing an unproven removal and a `./`-spelled unreviewed file kept. Backlog: "### Groom removes security entries without proof of a fix (`sprint-planning` security Low (6))", "### Sprint security continuation drops differently spelled unreviewed files (`sprint-planning` security Low (5))", "### Groom's fixed check accepts any ancestor commit (`sprint-planning` quality advisory)".
3. `secret-patterns` (T1 pipeline security, estimated small, merge-gate rules, alone): `tools/rules.sh` ASSIGN_RE, TOKEN_RE. Backlog: "## The secret patterns miss unquoted assignments and unlisted token shapes".
4. `merge-record-check` (T1 pipeline defect, estimated small): 3 of 6 backlog merges (#161, #162, #166) recorded a wrong CI or merge head. Accepted when tools-test refuses a CI head not the pushed head, or a merged commit not on main.
5. `ruby-structure-remove` (T2 user request, estimated medium, pushed back 3, first of the next backlog sprint by aging): #147 took a 100,000-line open from 22 to 116 ms. Backlog: #147's 7 entries (sprint-9).
6. `spinel-notice` (T2 user request, estimated medium, beyond the sprint by the user): "### Spinel's MIT notice does not travel with the vendored generated header (README.md:212)".
7. `content-gate-gaps` (T1 security Lows (5) to (3), estimated medium, pushed back 15): batch 1's other 4: "## A security review stays current after later instruction-file commits", "## pr-on-push security Low at tools/open_pr.sh:118", "## pr-on-push security Low at .github/workflows/open-pr.yml:39", "## Security Lows of the periodic review at 186ddfb".
8. `lane-guards` (T1 pipeline security, defect, estimated medium): checks-and-pr-lows Lows (5), (4), (4), (3) (sprint-12 Low (5) `deliver-change.js:511` the same); sprint-10 Low (5) `run_state.sh:2350`.
9. `lane-records` (T1 pipeline defect, estimated small): sprint-10 note 1 (`run_state.sh:1708`); "### plan-apply and history write into whatever checkout runs them".
10. `review-pipeline-b` (T1 pipeline, estimated medium): #166 reviews 83,029 of 235,968 output (35.2%). "## The review continuations run one after the other".
11. `git-signs-correctness` (T6 correctness, estimated medium, split at its start): sprint-12 notes 3 to 7; git-signs-status-b's 4 findings, "### git_signs counts stay stale after a fetch", "### git_signs shows no signs for a file committed empty".
12. `windows-buffers-walk` (T6 performance, estimated small): `tab_list.rb:168`, `:186`, `:205`, `:284`, `buffer_list.rb:407`. "## Five methods walk every window of every tab page".
13. `buffer-commands-tidy` (T6, estimated small): `:b 0000000001` E86; "### Three ex handlers spell digits? apart", "### The :e and :w messages still print a newline in a file name as a line break".
14. `lsp-sync-fixes` (T6 correctness, estimated medium, split at its start): `json_rpc_language_gateway.rb:1331`; "### The gateway's six cancel wrappers share one body".
15. `process-capture-hardening` (T3 security Lows, estimated medium, pushed back 1): `process_runner.rb:98` Low (5), `plugin_host.rb:110` Low (3).
16. `ci-hardening` (T3 with T6, estimated medium, pushed back 23): "### CI checkout keeps GITHUB_TOKEN while pull request targets run", "### Workflow actions are pinned by movable tags".
17. `tools-fail-open` (T1 pipeline defect, estimated medium): "### Scanner errors pass the text gates", "### metrics.sh compare passes a base name never measured", "### gate_pushes passes a non-numeric count", "### ci_scope.sh splits changed paths at whitespace".
18. `merge-gate-integrity` (T1 pipeline defect, estimated medium, pushed back 14): merge over 12 calls in 8 of 20 lane rows (lsp-container 15, planner-split-rule 14).
19. `scout-value`, `check-skip`, `records-trim`, `budget-prediction`, `plan-apply-guard`, `run-resume` (T1 pipeline, estimated small each, pushed back up to 17): lsp-container scout 25.9% of output. Retro sprint-12-records note 4: bench 6,460 of 36,282 output (17.8%) and 10 of 79 calls on a docs-only run, equal to main 3 of 3, goes to `check-skip`; note 5: groom output hand-edited in 2 of the last 3 records runs, 3 of 3 advisories on it, goes to `records-trim`.
20. `review-demotion`, `hook-one-place`, `gate-object-pin`, `own-line-advisories`, `prose-grep-cases`, `spec-tests-first`, `ci-workflow-tidy` (T1 pipeline, estimated medium each, pushed back up to 4).
21. `backlog-read-guard`, `record-tier`, `plan-skip`, `sprint-marker-tidy` (T1 pipeline, estimated small each).
22. `open-pr-refusals`, `check-runner-safety` (T1 security, estimated medium each, pushed back 3 and 15); `ci-scope-quoting` (T1, Low (6), estimated medium).
23. `gateway-split-a`, `gateway-split-b`, `frame-painters`, `plugin-api-split`, `language-followers`, `language-ask-port` (T5 architecture, estimated medium each).
24. `file-access-tidy` (T4 with T6, estimated medium, pushed back 26).
25. `architecture-docs` (T6, estimated small): carat.rb, PluginApi 2.7, map drift entries of sprint-12.
26. `plugin-host-tidy` (T6, estimated medium, pushed back 8): batch 2's 7 area-15 tidy entries.
27. `periodic-blockers-b`, `ex-handlers-tidy`, `input-core-tidy`, `ui-code-tidy`, `tools-docs-tidy`, `editing-counts`, `hover-tidy`, `signature-tidy`, `slots-tidy`, `completion-tidy`, `completion-docs-tidy`, `buffer-list-tidy`, `definitions-tidy`, `core-correctness-b`, `editing-dedup-a`, `editing-dedup-b` (T6, estimated medium each, pushed back up to 16).
28. `docs-index` (T6, estimated medium, pushed back 21, split at its start).

## Decisions

- Security first clear (T0): no High or Medium at confidence 8 or above; sprint-security's Medium (7) is below 8, sprint-12 sweep high=0 medium=0, no review.periodic in pending sprint-12-records.
- Delivered: `sprint-security` part a (T1 pipeline defect, security Medium (7) and the partial-report advisory) removed from Sprint 13 by the user's brief; `git-signs-transport` is now Sprint 13 item 1.
- Split rule: the 6-heading item held five independently testable parts (pushed back 15); its Lows (6), (5) and the fixed advisory are `sprint-security-b` (T1, estimated small), pool 2 after `toolchain-clean-scope` (data loss), by the user's brief.
- Estimate medium for part a: T1 backlog rows planner-split-rule 751,218/35 min, review-pipeline-a 765,652/32, checks-and-pr-lows 1,125,404/67; of the last two rows only windows-buffers-tidy 1,373,899 went over 1.2M, so no size up.
- Part a holds two testable parts (closure refusals with the partial report; findings recorded without the skeptic), under the three of the split rule.
- Retro notes 4 and 5 of sprint-12-records (bench 6,460/10 calls on a docs-only run; groom hand edit in 2 of 3 records runs) fold into `check-skip` and `records-trim` (T1), entries in this plan's backlog.md.
- Quality first pass 65/129 over all changes; sprint-12-records quality notes 1 to 3 already handled.
- Carried: 27 unmapped headings left for `docs-index`; backlog triage done once (9b764e3, b31fcd5); "## Five methods walk every window of every tab page" kept for `windows-buffers-walk`.
