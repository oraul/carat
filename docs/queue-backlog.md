# Queue: backlog

Ordered by `docs/goals.md`; folded findings are in `docs/backlog.md`. Every fix is accepted with `lh` 26.0, `j` 27.0, `insert` 26.0 held.

## Sprint 18

Backlog 3 of 3 delivered: `groom-proof`, `backlog-throughput`, `sign-colors`.

## Pool

1. `lsp-tidy` (T6 with security Lows (5), (4), (3) and a correctness bug, estimated medium, backlog-pick batch 2 part a): `ProcessRunner#stop` (`carat/drivers/process_runner.rb`) detaches a server that ignores its input's end, so it outlives the editor (Low (5)); `sync` and `poll` (`carat/adapters/json_rpc_language_gateway.rb:205`, `:430`) send files outside the trusted root (Lows (3), (4)); `path_of` (`:789`) keeps dot segments; `ProcessRunner#write` (`process_runner.rb:55`) answers true after its writer stopped; `start` and `restart` repeat a message (`:88`, `:112`), `hold` repeats `launch` (`:228`); `LanguageServer#words` is never read (`carat/domain/language_server.rb:11`); no test shows a refused spawn is not retried (`test/adapters_language_gateway.rb:173`). Lines at their entries' commits. Fix outline: the server ended, only trusted files sent, the port's contract kept, one copy of each. Accepted when gateway and driver rows show a server ignoring its input ended, no notification for a file outside the root, a `..` path normalized, `write` false after the writer stopped, and 1 spawn after 2 idle ticks. Backlog: "## A language server that ignores the end of its input outlives the editor", "## Language servers are told about files outside the trusted root", "## ProcessRunner#write answers true after its writer stopped", "## The language server client repeats itself and names little of what it uses", "## The language server client has loose ends", "## No test shows a refused language server spawn is not retried", "## JsonRpcLanguageGateway#path_of keeps dot segments (periodic security Low at 186ddfb)".
2. `explorer-tidy` (T6 with a correctness bug, estimated medium, batch 3, pushed back 4, reason: the user's Sprint 18 choice): follow's cursor drifts, a non-right side opens left (`plugin.rb:516`); 10 Explorer headings.
3. `bench-scenarios` (T4, estimated small, Facet wave 1 item 6, before wave 3): bench skips lh-float, lh-winbar, n, palette (`bench/run.sh:73`).
4. `glyph-audit` (T2 user request, estimated small, Facet wave 2): ◆ ◇ ◈ ▣ ▸ mean two things each, 7 vertical marks.
5. `sprint-review-continuation` (T1 pipeline defect, security Low (5), estimated medium, part b of `groom-proof`): the sprint security continuation keeps only `not_reviewed` names spelled as the first start's (`.claude/workflows/sprint-planning.js:104`), so `./tools/run_state.sh` drops out and the review records pass (Low (5)); a capped quality review gets no continuation (`:175`); accepted when tools-test cases keep a differently spelled path not reviewed and give a capped quality review one continuation or record it partial; "### Sprint security continuation drops differently spelled unreviewed files (`sprint-planning` security Low (5))", "### The sprint quality review gets no continuation at its cap (`sprint-1` review quality)".
6. `backlog-throughput-b` (T1 pipeline efficiency, user request, estimated medium, parts b and c of `backlog-throughput`): the backlog grows about +35 headings a sprint (1,151 at sprint-10, 1,328 at sprint-15, about 1,450 now), 2 to 3 backlog items closing 10 to 15 entries against about 50 added; a batch holds 5 to 10 entries (`tools/run_state.sh:366`, `:367`); a feature delivery closes none of the entries in the files it edits. Accepted when tools-test cases show small one-area entries (wording, naming, docs, one-line tidy) drawn up to about 20 per delivery and never split for count alone, the split rule counting testable behavior, and a feature item naming at most 5 small entries located in files it edits; the next two sprints' grooms show the backlog holding or shrinking.
7. `round-limit-resume` (T1 defect, estimated small, with round-limit-bypass): a resume after stop none grants rounds past 3 (vim-line-commands-c rework 6, about 428,000 of 995,640 output); no rework above 3 without the user's approval.
8. `open-pr-retry` (T1 defect, estimated small): one API timeout fails open-pr, the re-run refused 403; a no-pull-request result on a moved main has no path; retry, then merge-main and the one push.
9. `pr-testing-truth` (T1 defect, estimated small): Testing written before the reviews (vim-line-commands-c: 4 of 6 rounds); written from recorded reviews, gated.
10. `stage-clean` (T1 defect, user request, estimated small): merged stages kept, 13 folders 1.4G pruned by hand; a deterministic `cleaner` agent runs `stage-clean` once after a recorded merge.
11. `rework-review-repeat` (T1 efficiency, estimated medium): later rounds repeat notes (reviews 301 of 578 calls, 366,936 output; facet-palette re-raised a declined advisory); advisory-only rounds rerun every review (sprint-17-records: 2 of 3 rounds, reviews 41.9% of output; guide-colors rework 1 from 4 advisories, 147,140 to 230,744 output; groom-proof a 0-blocking round at 200,212 of 200,000; backlog-throughput a docs-only round 67,553; facet-palette rework 2, 0 blocking); 2 review-phase headings.
12. `quality-first-pass` (T1 efficiency, estimated medium, with review-fix-treadmill): quality 91 of 162; re-reviews blocking on each fix round's code, 1, 3, 1, 1 (833,080 output); 7 of the next 10; 2 headings.
13. `spinel-bump` (T2 user request, toolchain, estimated medium, alone in its lane): `SPINEL_REF` c0502112d8 656 commits behind; make check, figures compared.
14. `check-clone-toolchain` (T1 defect, Medium (6), estimated medium, pushed back 2): `tools/run_state.sh:893`; 4 headings.
15. `periodic-clear-rules` (T1 defect, Medium (6), estimated medium): 7 headings.
16. `check-runner-safety` (T1 defect, Medium (6), estimated medium, pushed back 19): 3 headings.
17. `review-scope-pins` (T1 defect, Medium (4), estimated medium): 4 headings.
18. `sprint-security-b` (T1 defect, Lows, estimated medium): `tools/gates.sh:112`; 4 headings.
19. `ci-trust-gaps-b` (T1 defect, Low (6), estimated small), `ci-trust-gaps-c` (T1, Lows, estimated medium): 2 and 8 headings.
20. `toolchain-clean-scope` (T1 defect, data loss, estimated small): `Makefile:203`.
21. `check-pass-budget-flag` (T1 defect, estimated medium): false flags at 252,910 and 283,183 of 200,000, again groom-proof 200,212 to 306,481, guide-colors 230,744, backlog-throughput 399,564 and 467,117, facet-palette 204,127 to 573,120; check output 30-fold for one verdict (groom-proof 62,263 over 4 passes, facet-palette 123,463 in 6 calls, a clean pass 1,932); accepted at 5,000 or less per pass.
22. `records-plan-apply`, `bench-skip-no-code`, `moved-review-diff`, `advisory-findings-auto`, `merge-output-cap` (merge output on a green CI: guide-colors 26,423 in 11 calls, backlog-throughput 137,609 in 14), `scout-prune-step`, `doc-budget-room` (planner.md 8,190 of 8,192 bytes, CLAUDE.md 30,717 of 30,720; room by removing repeats) (T1 pipeline, estimated small each).
23. `groom-fold-format` (T1 defect, estimated small): the vim-folds-b findings file folded 7 headings twice; removed findings files leave references (sprint-17-records: 3 hand edits); a findings file keeps entries fixed in place (groom-proof: 5 entries, 1 open at the last head); `merge-main-queue-conflict` (T1, estimated medium).
24. `normal-command-fixes` (T3 Low (6), estimated large): `:normal` remap depth 100 hangs (`carat/use_cases/ex/normal_command_handler.rb:62`).
25. `file-access-color` (T3 Low (3), estimated medium): 4 headings.
26. `motions-search-tidy-b` (T4, estimated medium): 96 ms and 1.5 s per key.
27. `plugin-host-tidy`, `input-bytes-tidy`, `frame-presenter-tidy`, `motions-search-tidy-c` (T6, estimated medium each).

## Decisions

- `sign-colors` delivered, off Sprint 18 (T2 user request, a defect): item 1 at d91f1ba as written; Sprint 18 backlog 3 of 3 with `groom-proof` and `backlog-throughput`.
- Estimate medium, not small (T2, size rule): palette-narrow 736,843 / 51.2 min, bar-colors 879,991 / 48.2, guide-colors 922,993 / 73.0, all over small's 500k and 25 min; the last 2 comparable under 1.2M, no size up; the lane's last 2 over (sprint-17-records 857,102 of 500k, groom-proof 1,444,297 of 1.2M) are records and tooling runs.
- No split (T2, the brief "delivered as written"): 1 mechanism, a group per sign by its icon name; 2 dependent paths (diagnostic, plugin); map areas 8, 13, 14 edited, 15 a pass-through; 1 acceptance check.
- No `tools/rules.sh` edit (T1): the brief touches signs, themes, the presenter, and their tests.
- Security first empty (T0): backlog-throughput and facet-palette security high=0 medium=0; no `review.periodic` record in the 2 pending runs.
- backlog-throughput retro 12 and facet-palette retros 10, 11 into `rework-review-repeat` (T1): a docs-only round 67,553 output; rework 2 with 0 blocking.
- backlog-throughput overruns 9, 10, facet-palette overruns 7 to 9 and retro 12's check part into `check-pass-budget-flag` (T1): 399,564 to 573,120 of 200,000.
- backlog-throughput retro 11 and facet-palette retro 12's merge part into `merge-output-cap` (T1): merge 137,609 output in 14 calls, green CI.
- backlog-throughput retro 13 as `doc-budget-room` in Pool 22 (T1): planner.md 8,190 of 8,192 bytes, CLAUDE.md 30,717 of 30,720.
- backlog-throughput overrun 14 (groom-proof 1,444,297 of 1.2M) dropped, placed already by that run's size decision (T1).
