# Queue: backlog

Ordered by `docs/goals.md`; folded findings are in `docs/backlog.md`. Every fix is accepted with `lh` 26.0, `j` 27.0, `insert` 26.0 held.

## Sprint 18

1. `groom-proof` (T1 pipeline defect, security Low (6), (5), estimated medium, backlog-pick batch 1 part a): groom's `listed` accepts any archived change whose name ends in the change and `fixed` any ancestor commit, even the root (`tools/run_state.sh:2374`), so a security entry can leave unfixed (Low (6)); its guard greps for the word security (`tools/run_state.sh:2413`), refusing a duplicate retro entry quoting "Security first section" and stopping sprint-17-records; the sprint security continuation in `.claude/workflows/sprint-planning.js` keeps only `not_reviewed` names spelled as the first start's, so `./tools/run_state.sh` drops out and the review records pass (Low (5)); a capped sprint quality review gets no continuation. Fix outline: removals provable from the sprint's merged changes and range; the guard reads a real severity marker; the continuation fails closed. Accepted when tools-test cases refuse `listed` by a change outside the sprint or whose item lacks the heading, refuse `fixed` by a commit outside the sprint's range or not touching the heading's file, remove a duplicate whose text only mentions security, keep a differently spelled path not reviewed, and give a capped quality review one continuation or record it partial. Backlog: "### Groom removes security entries without proof of a fix (`sprint-planning` security Low (6))", "### Sprint security continuation drops differently spelled unreviewed files (`sprint-planning` security Low (5))", "### Groom's fixed check accepts any ancestor commit (`sprint-planning` quality advisory)", "### The sprint quality review gets no continuation at its cap (`sprint-1` review quality)".
2. `sign-colors` (T2 user request, a defect, estimated small, Facet wave 1 item 3): every sign is painted SignColumn yellow, error signs (`carat/domain/buffer.rb:374`) and git's added, changed, deleted (`carat/plugins/git_signs/plugin.rb:46`) alike; `place_sign` (`carat/use_cases/plugins/buffer_requests.rb:101`) takes an icon name but no group. Fix outline: a group per sign by its icon name, no API change. Accepted when frame rows on carat-dark and carat-light show an error sign red, a warning yellow, git added green and changed cyan. Backlog: none.
3. `lsp-tidy` (T6 with security Lows (5), (4), (3) and a correctness bug, estimated medium, backlog-pick batch 2 part a): `ProcessRunner#stop` (`carat/drivers/process_runner.rb`) detaches a server that ignores its input's end, so it outlives the editor (Low (5)); `sync` and `poll` (`carat/adapters/json_rpc_language_gateway.rb:205`, `:430`) send files outside the trusted root (Lows (3), (4)); `path_of` (`:789`) keeps dot segments; `ProcessRunner#write` (`process_runner.rb:55`) answers true after its writer stopped; `start` and `restart` repeat a message (`:88`, `:112`), `hold` repeats `launch` (`:228`); `LanguageServer#words` is never read (`carat/domain/language_server.rb:11`); no test shows a refused spawn is not retried (`test/adapters_language_gateway.rb:173`). Lines at their entries' commits. Fix outline: the server ended, only trusted files sent, the port's contract kept, one copy of each. Accepted when gateway and driver rows show a server ignoring its input ended, no notification for a file outside the root, a `..` path normalized, `write` false after the writer stopped, and 1 spawn after 2 idle ticks. Backlog: "## A language server that ignores the end of its input outlives the editor", "## Language servers are told about files outside the trusted root", "## ProcessRunner#write answers true after its writer stopped", "## The language server client repeats itself and names little of what it uses", "## The language server client has loose ends", "## No test shows a refused language server spawn is not retried", "## JsonRpcLanguageGateway#path_of keeps dot segments (periodic security Low at 186ddfb)".

## Pool

1. `explorer-tidy` (T6 with a correctness bug, estimated medium, batch 3, pushed back 4, reason: the user's Sprint 18 choice): follow's cursor drifts, a non-right side opens left (`plugin.rb:516`); 10 Explorer headings.
2. `bench-scenarios` (T4, estimated small, Facet wave 1 item 6, before wave 3): bench skips lh-float, lh-winbar, n, palette (`bench/run.sh:73`).
3. `glyph-audit` (T2 user request, estimated small, Facet wave 2): ◆ ◇ ◈ ▣ ▸ mean two things each, 7 vertical marks.
4. `round-limit-resume` (T1 defect, estimated small, with round-limit-bypass): a resume after stop none grants rounds past 3 (vim-line-commands-c rework 6, about 428,000 of 995,640 output); no rework above 3 without the user's approval.
5. `open-pr-retry` (T1 defect, estimated small): one API timeout fails open-pr, the re-run refused 403; a no-pull-request result on a moved main has no path; retry, then merge-main and the one push.
6. `pr-testing-truth` (T1 defect, estimated small): Testing written before the reviews (vim-line-commands-c: 4 of 6 rounds); written from recorded reviews, gated.
7. `stage-clean` (T1 defect, user request, estimated small): merged stages kept, 13 folders 1.4G pruned by hand; a deterministic `cleaner` agent runs `stage-clean` once after a recorded merge.
8. `rework-review-repeat` (T1 efficiency, estimated medium): later rounds repeat notes (reviews 301 of 578 calls, 366,936 output); 2 review-phase headings.
9. `quality-first-pass` (T1 efficiency, estimated medium, with review-fix-treadmill): quality 91 of 162; re-reviews blocking on each fix round's code, 1, 3, 1, 1 (833,080 output); 7 of the next 10; 2 headings.
10. `spinel-bump` (T2 user request, toolchain, estimated medium, alone in its lane): `SPINEL_REF` c0502112d8 656 commits behind; make check, figures compared.
11. `check-clone-toolchain` (T1 defect, Medium (6), estimated medium, pushed back 2): `tools/run_state.sh:893`; 4 headings.
12. `periodic-clear-rules` (T1 defect, Medium (6), estimated medium): 7 headings.
13. `check-runner-safety` (T1 defect, Medium (6), estimated medium, pushed back 19): 3 headings.
14. `review-scope-pins` (T1 defect, Medium (4), estimated medium): 4 headings.
15. `sprint-security-b` (T1 defect, Lows, estimated medium): `tools/gates.sh:112`; 4 headings.
16. `ci-trust-gaps-b` (T1 defect, Low (6), estimated small), `ci-trust-gaps-c` (T1, Lows, estimated medium): 2 and 8 headings.
17. `toolchain-clean-scope` (T1 defect, data loss, estimated small): `Makefile:203`.
18. `check-pass-budget-flag` (T1 defect, estimated small): false flags at 252,910 and 283,183 of 200,000.
19. `records-plan-apply`, `bench-skip-no-code`, `moved-review-diff`, `advisory-findings-auto`, `merge-output-cap`, `scout-prune-step` (T1 pipeline, estimated small each).
20. `groom-fold-format` (T1 defect, estimated small): the vim-folds-b findings file folded 7 headings twice; `merge-main-queue-conflict` (T1, estimated medium).
21. `normal-command-fixes` (T3 Low (6), estimated large): `:normal` remap depth 100 hangs (`carat/use_cases/ex/normal_command_handler.rb:62`).
22. `file-access-color` (T3 Low (3), estimated medium): 4 headings.
23. `motions-search-tidy-b` (T4, estimated medium): 96 ms and 1.5 s per key.
24. `plugin-host-tidy`, `input-bytes-tidy`, `frame-presenter-tidy`, `motions-search-tidy-c` (T6, estimated medium each).

## Decisions

- Sprint 18, 3 features, 3 backlog (T1, T2, T6): `groom-proof`, `sign-colors`, `lsp-tidy`, the user's order (2026-11-18); batches 1, 2 (Build and CI 10 of 628, Ports 10 of 136); batch 3 (Explorer 10 of 18) to Sprint 19 with `bench-scenarios`; 1 pipeline item, a defect; 31 `unmapped:` left.
- Main session's pipeline defects placed (T1): `open-pr-retry`, `pr-testing-truth`, `stage-clean`, `spinel-bump` alone; round-limit-bypass and review-fix-treadmill merged.
- Batch 1 split (T1, size rule): 10 headings in 4 parts; the 4 groom headings now, 2 review-phase headings to `rework-review-repeat`, 2 pr-on-push to `ci-trust-gaps-c`, gates.sh:112 to `sprint-security-b`, 186ddfb to `check-clone-toolchain`, its `path_of` part split into an lsp entry.
- Batch 2 split (T6): 6 language-server headings plus `path_of` now; MakePath, DiskFiles, and 2 NO_COLOR to `file-access-color`; old pool `lsp-tidy` merged.
- `round-limit-resume` queued first in the pool (T1 defect): vim-line-commands-c retro 104, rework 6, 3 extra rounds.
- Retros merged (T1): squash-body-full 11 and vim-line-commands-c 103 into `rework-review-repeat`; squash-body-full 12 and vim-line-commands-c 105 into `quality-first-pass`.
- `normal-command-fixes` queued (T3): vim-line-commands-c security Low (6) at `carat/use_cases/ex/normal_command_handler.rb:62` and 11 late findings, groomed into entries.
- Sprint-17 review placed (T1, T6): Low (4) `tools/agent_guard.sh:950` to `ci-trust-gaps-c`; quality 2, 3, 4, 6, 7 already recorded; 5, 8 to 11 groomed.
- Overruns true flags (T1): squash-body-full check pass 283,183 of 200,000; vim-line-commands-c 949,139 at rework 6.
- Groom (T1): 3 listed, 5 fixed by 539235d, 522a0e1, 37e72e3, 6 repeated headings; the planner-files pair kept, refused by `tools/run_state.sh:2413`; the spinel-notes.md:47 pair kept; triage done.
- Security first empty (T0): no High or Medium at 8 or above in sprint-17, none disputed.
