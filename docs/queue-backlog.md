# Queue: backlog

Ordered by `docs/goals.md`; folded findings are in `docs/backlog.md`. Every fix is accepted with `lh` 26.0, `j` 27.0, `insert` 26.0 held.

## Sprint 18

1. `sign-colors` (T2 user request, a defect, estimated small, Facet wave 1 item 3): every sign is painted SignColumn yellow, error signs (`carat/domain/buffer.rb:374`) and git's added, changed, deleted (`carat/plugins/git_signs/plugin.rb:46`) alike; `place_sign` (`carat/use_cases/plugins/buffer_requests.rb:101`) takes an icon name but no group. Fix outline: a group per sign by its icon name, no API change. Accepted when frame rows on carat-dark and carat-light show an error sign red, a warning yellow, git added green and changed cyan. Backlog: none.
2. `lsp-tidy` (T6 with security Lows (5), (4), (3) and a correctness bug, estimated medium, backlog-pick batch 2 part a): `ProcessRunner#stop` (`carat/drivers/process_runner.rb`) detaches a server that ignores its input's end, so it outlives the editor (Low (5)); `sync` and `poll` (`carat/adapters/json_rpc_language_gateway.rb:205`, `:430`) send files outside the trusted root (Lows (3), (4)); `path_of` (`:789`) keeps dot segments; `ProcessRunner#write` (`process_runner.rb:55`) answers true after its writer stopped; `start` and `restart` repeat a message (`:88`, `:112`), `hold` repeats `launch` (`:228`); `LanguageServer#words` is never read (`carat/domain/language_server.rb:11`); no test shows a refused spawn is not retried (`test/adapters_language_gateway.rb:173`). Lines at their entries' commits. Fix outline: the server ended, only trusted files sent, the port's contract kept, one copy of each. Accepted when gateway and driver rows show a server ignoring its input ended, no notification for a file outside the root, a `..` path normalized, `write` false after the writer stopped, and 1 spawn after 2 idle ticks. Backlog: "## A language server that ignores the end of its input outlives the editor", "## Language servers are told about files outside the trusted root", "## ProcessRunner#write answers true after its writer stopped", "## The language server client repeats itself and names little of what it uses", "## The language server client has loose ends", "## No test shows a refused language server spawn is not retried", "## JsonRpcLanguageGateway#path_of keeps dot segments (periodic security Low at 186ddfb)".

## Pool

1. `explorer-tidy` (T6 with a correctness bug, estimated medium, batch 3, pushed back 4, reason: the user's Sprint 18 choice): follow's cursor drifts, a non-right side opens left (`plugin.rb:516`); 10 Explorer headings.
2. `bench-scenarios` (T4, estimated small, Facet wave 1 item 6, before wave 3): bench skips lh-float, lh-winbar, n, palette (`bench/run.sh:73`).
3. `glyph-audit` (T2 user request, estimated small, Facet wave 2): ◆ ◇ ◈ ▣ ▸ mean two things each, 7 vertical marks.
4. `sprint-review-continuation` (T1 pipeline defect, security Low (5), estimated medium, part b of `groom-proof`): the sprint security continuation keeps only `not_reviewed` names spelled as the first start's (`.claude/workflows/sprint-planning.js:104`), so `./tools/run_state.sh` drops out and the review records pass (Low (5)); a capped quality review gets no continuation (`:175`); accepted when tools-test cases keep a differently spelled path not reviewed and give a capped quality review one continuation or record it partial; "### Sprint security continuation drops differently spelled unreviewed files (`sprint-planning` security Low (5))", "### The sprint quality review gets no continuation at its cap (`sprint-1` review quality)".
5. `round-limit-resume` (T1 defect, estimated small, with round-limit-bypass): a resume after stop none grants rounds past 3 (vim-line-commands-c rework 6, about 428,000 of 995,640 output); no rework above 3 without the user's approval.
6. `open-pr-retry` (T1 defect, estimated small): one API timeout fails open-pr, the re-run refused 403; a no-pull-request result on a moved main has no path; retry, then merge-main and the one push.
7. `pr-testing-truth` (T1 defect, estimated small): Testing written before the reviews (vim-line-commands-c: 4 of 6 rounds); written from recorded reviews, gated.
8. `stage-clean` (T1 defect, user request, estimated small): merged stages kept, 13 folders 1.4G pruned by hand; a deterministic `cleaner` agent runs `stage-clean` once after a recorded merge.
9. `rework-review-repeat` (T1 efficiency, estimated medium): later rounds repeat notes (reviews 301 of 578 calls, 366,936 output); advisory-only rounds rerun every review (sprint-17-records: 2 of 3 rounds, reviews 41.9% of output); 2 review-phase headings.
10. `quality-first-pass` (T1 efficiency, estimated medium, with review-fix-treadmill): quality 91 of 162; re-reviews blocking on each fix round's code, 1, 3, 1, 1 (833,080 output); 7 of the next 10; 2 headings.
11. `spinel-bump` (T2 user request, toolchain, estimated medium, alone in its lane): `SPINEL_REF` c0502112d8 656 commits behind; make check, figures compared.
12. `check-clone-toolchain` (T1 defect, Medium (6), estimated medium, pushed back 2): `tools/run_state.sh:893`; 4 headings.
13. `periodic-clear-rules` (T1 defect, Medium (6), estimated medium): 7 headings.
14. `check-runner-safety` (T1 defect, Medium (6), estimated medium, pushed back 19): 3 headings.
15. `review-scope-pins` (T1 defect, Medium (4), estimated medium): 4 headings.
16. `sprint-security-b` (T1 defect, Lows, estimated medium): `tools/gates.sh:112`; 4 headings.
17. `ci-trust-gaps-b` (T1 defect, Low (6), estimated small), `ci-trust-gaps-c` (T1, Lows, estimated medium): 2 and 8 headings.
18. `toolchain-clean-scope` (T1 defect, data loss, estimated small): `Makefile:203`.
19. `check-pass-budget-flag` (T1 defect, estimated small): false flags at 252,910 and 283,183 of 200,000.
20. `records-plan-apply`, `bench-skip-no-code`, `moved-review-diff`, `advisory-findings-auto`, `merge-output-cap`, `scout-prune-step` (T1 pipeline, estimated small each).
21. `groom-fold-format` (T1 defect, estimated small): the vim-folds-b findings file folded 7 headings twice; removed findings files leave references (sprint-17-records: 3 hand edits); `merge-main-queue-conflict` (T1, estimated medium).
22. `normal-command-fixes` (T3 Low (6), estimated large): `:normal` remap depth 100 hangs (`carat/use_cases/ex/normal_command_handler.rb:62`).
23. `file-access-color` (T3 Low (3), estimated medium): 4 headings.
24. `motions-search-tidy-b` (T4, estimated medium): 96 ms and 1.5 s per key.
25. `plugin-host-tidy`, `input-bytes-tidy`, `frame-presenter-tidy`, `motions-search-tidy-c` (T6, estimated medium each).

## Decisions

- `groom-proof` delivered from Sprint 18 item 1 at 7d9bf2a, removed (T1 pipeline defect, security Low (6)): Sprint 18 keeps `sign-colors`, `lsp-tidy`.
- Split in two (T1, size rule): 4 testable parts in 2 areas; part a `groom-proof`, groom's `listed`, `fixed`, and guard (`tools/run_state.sh:2410`, `:2413`), 2 groom headings; part b `sprint-review-continuation` to Pool 4, 2 headings.
- Estimate medium per part (T1): merge-main-path 814,062 / 36.9 min, moved-review-carry 1,028,455 / 53.7; the whole brief up to large as the last 2 lane runs went over 1,200,000 (1,314,641, 1,206,650), split as large outside the roadmap.
- No merge-gate rule edit (T1): `tools/rules.sh` untouched, the edits in `tools/run_state.sh` and `sprint-planning.js`.
- `sprint-review-continuation` ahead of `round-limit-resume` (T1, security Low (5)): a review record passing unreviewed outranks a rework cap.
- Security first empty (T0): sprint-17-records security high=0 medium=0; no `review.periodic` record in the 1 pending run.
- sprint-17-records retro 8 into `rework-review-repeat` (T1): reviews 30,387 of 72,515 output, 2 of 3 rounds advisory-only.
- Retro 9 into `groom-fold-format` (T1): 3 hand edits, 1 of 5 advisories.
- Retro 10 into `bench-skip-no-code`, a near-duplicate (T1): bench 4,147 output, 6 calls, 10 of 10 keys equal.
- Overrun note 11 placed already (T1): vim-line-commands-c 3,966,863 of 1,200,000 in `round-limit-resume`.
