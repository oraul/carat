# Queue: backlog

Ordered by `docs/goals.md`; folded findings are in `docs/backlog.md`. Every fix is accepted with `lh` 26.0, `j` 27.0, `insert` 26.0 held.

## Sprint 19

The user-approved exception (2026-11-18): pipeline speedups, not defects, in this order. Evidence: 0 rework rounds take 37-43 min, 2-3 rounds 70-95 min; 496 of 529 findings in the last 45 runs were advisory.

1. `review-lite` (T1 pipeline, user request, estimated medium): a fix round answering only advisories reruns the whole verification: the check rebuilds (`.claude/workflows/deliver-change.js:1197`) and the security review reads the branch (`:1069`) when no code changed; sign-colors rework 2 with 0 blocking, 71,651 output after its first check pass, security 0 each time. Fix outline: a round whose fixes touch only advisory items (docs, comments, spec text, small cleanups) runs no rebuild and no security review when no code changed, and its quality review reads only the changed lines (`:876`); a blocking bug or any code change keeps the full round. Accepted when workflow test cases show a docs-only advisory round skipping the check and the security review with the skip recorded, its quality review scoped to the changed lines, and a round with code or a blocking finding running in full; then over the next 5 runs with 0 blocking, none past one fix round. Backlog: "### Advisory-only rework rounds cost half of facet-palette's output", "### Advisory-only fix rounds cost a full review round (guide-colors retro, merged)", "### Advisory-only fix rounds cost a full review round (sprint-17-records retro)".
2. `quality-first-pass` (T1 pipeline, user request, estimated medium): quality passes first 94 of 169 runs against check 165/169 and security 162/169; the reviewer is told to report every blocking finding in a first pass (`.claude/agents/quality-reviewer.md:21`), yet later rounds still raise new ones on code the first pass read, and only a re-raise at an earlier advisory's location is caught (`deliver-change.js:1110`). Fix outline: the first pass reports every finding it can; a later blocking finding on lines unchanged since the first pass is recorded as a first-pass miss. Accepted when a workflow test case notes such a finding as a first-pass miss, and quality passes first on 7 of the next 10 runs. Backlog: "### Quality fails its first pass on about half the runs".
3. `contributor-checklist` (T1 pipeline, user request, estimated medium, parts a and c): quality fails first on 75 of 169 runs from findings a checklist catches (plugin-lazy-activate: a stale test expectation, a raise branch untested); the self-check (`.claude/agents/contributor.md:38`) names no edge case. Fix outline: a checklist from real findings (empty range, CRLF, UTF-16 and multi-byte, trailing blanks, last line, empty buffer; a test per behavior change; search for an existing helper before writing; comments, docs, and spec text match the code), and the contributor self-reviews its diff with the quality reviewer's instructions before returning, within contributor.md's budget. Accepted when contributor.md's self-check names each of those points and the self-review, docs-lint budgets hold, and quality passes first on 8 of the next 10 runs. Backlog: "### The quality review fails its first pass most often, and its round costs most (plugin-lazy-activate retro)", "### The contributor returns work the quality review blocks on its first pass (plugin-lazy-activate retro 11)".

## Pool

1. `check-runner-safety` (T1 defect, Medium (6), estimated medium, pushed back 19, Sprint 20 pipeline-defect slot, the user's rule): 3 headings; reviewers run the branch's Makefile (`agent_guard.sh:590`, sweep Medium (5)).
2. `pr-trust-lows` (T1 pipeline defect, security Medium (4), Lows (4), (4), (3), estimated medium, pushed back 1, batch 1 part a): `tools/spec_validate.sh:17`, `tools/open_pr.sh:118`, `:190`, `open-pr.yml:39`; "## OpenSpec runs unpinned beside the push credentials (sprint-2 sweep security Medium (4))", "## pr-on-push security Low at tools/open_pr.sh:118", "## pr-on-push security Low at .github/workflows/open-pr.yml:39", "### Restrict the open-pr edit path to same-repository pull requests (security Low, confidence 4)".
3. `render-tidy` (T6 with security Low (5), estimated medium, pushed back 1, batch 2 part a): `screen_presenter.rb:30`, `frame_presenter.rb:569`, `:382`, `:201`; "### Bracketed paste is never enabled (sprint-14 sweep security Low (5))", "## Match highlighting walks matches left of the scroll and keeps rows painted after the budget stopped", "## FramePresenter passes the painted row through instance variables", "## FramePresenter clears the layout twice for the hit-enter prompt and the start screen", "## The screen presenter's first painted row test accepts two outputs".
4. `file-access-color` (T3 security Lows (3), (3), estimated medium, pushed back 1, batch 3 part a): `disk_files.rb:33`, `:57`, `rc_config_gateway.rb:59`, `editor_assembly.rb:489`; "### MakePath and the project .caratrc check follow a link swapped after the probe (sprint-14 sweep security Low (3), Low (3))", "## DiskFiles#stat makes four system stats per path", "## NO_COLOR leaves syntax, bars, and messages colored", "## No test reads NO_COLOR through AnsiTerminal".
5. `lsp-tidy` (T6 with Lows (5), (4), (3), estimated medium, Sprint 20 by the user's request, pushed back 3, reason: the user's request, at the limit of 3): `process_runner.rb:55`, `:124`, `json_rpc_language_gateway.rb:205`, `:430`, `:789`; its 7 Sprint 18 headings.
6. `contributor-checklist-b` (T1 pipeline, user request, estimated small, parts b and d, after `doc-budget-room`): a finding repeated 3 or more times becomes a lint or gates check; the planner's brief names the area's edge cases (planner.md 8,179 of 8,192).
7. `test-one-alone` (T4, user request, estimated small): `make test-one T=test/use_cases_plugins.rb` does not compile alone on main, void-value errors in `carat/use_cases/history/list_undo.rb`, `carat/use_cases/history/walk_history.rb`, `carat/use_cases/dispatcher.rb` (sign-colors note 16); accepted when it compiles and passes alone.
8. `lsp-tidy-b` (T6 with Lows (5), (4), estimated medium, batch 3 part b): "## A save while the language server starts is never sent", "## The language server outbox has no bound", "## Published diagnostics keep any number of URIs", "## The gateway's apply has an unclear name and a needless branch", "## ControlText.cleaned is public with a flag argument", "## The published helper's comment in the LSP test is wrapped unevenly".
9. `render-tidy-b` (T6, estimated medium, batch 2 part b): "## Illegal bytes are drawn as U+FFFD, not as hexadecimal markers", "## code_of decodes UTF-8 inside DisplayWidth", "## DisplayWidth.of_char has no caller", "## StartArt#paint clamps a step no caller passes out of range", "## StartArt.from_plain bends the from_x naming".
10. `skill-guard` (T1 defect, Medium (6), estimated small): the agents' Skill tool is in no hook matcher (`tools/agent_guard.sh:1071`).
11. `explorer-tidy` (T6 with a bug, estimated medium, pushed back 5, reason: backlog-pick first): `plugin.rb:516`; 10 headings.
12. `vim-compat-fixes` (T6 bugs, estimated medium): count overflow (`command_grammar.rb:98`), `ci"` on `""` (`text_objects.rb:356`), `{` at 0,0 (`motions.rb:550`), `\V[` (`vim_pattern.rb:134`).
13. `bench-scenarios` (T4, estimated small): 4 scenarios skipped (`bench/run.sh:73`).
14. `glyph-audit` (T2 user request, estimated small): 5 glyphs mean two things each.
15. `sprint-review-continuation` (T1 defect, Low (5), estimated medium): `sprint-planning.js:104`, `:175`; 2 headings.
16. `backlog-throughput-b` (T1, user request, estimated medium): +35 headings a sprint.
17. `round-limit-resume`, `open-pr-retry`, `pr-testing-truth`, `stage-clean` (T1 defects, estimated small each).
18. `rework-review-repeat` (T1, estimated medium, with review-fix-treadmill): later rounds repeat notes and block on each fix round's code (1, 3, 1, 1, 833,080 output); "### A re-review re-raised an advisory declined for the brief's reason"; 2 review-phase headings.
19. `spinel-bump` (T2 user request, estimated medium): 656 commits behind.
20. `check-clone-toolchain`, `periodic-clear-rules` (T1 defects, Medium (6), estimated medium each, pushed back 2): 4 and 7 headings.
21. `review-scope-pins` (T1 defect, Medium (4), estimated medium): 4 headings.
22. `sprint-security-b` (T1 defect, Lows, estimated medium, with batch 1 part b): `tools/gates.sh:112`; "## A security review after a quality-only fix reads the whole branch again", "## The review continuations run one after the other".
23. `ci-trust-gaps-b`, `ci-trust-gaps-c` (T1, Lows, estimated medium): 10 headings; `ci.yml:54` (sweep Low (3)).
24. `toolchain-clean-scope` (T1 defect, estimated small): `Makefile:203`.
25. `check-pass-budget-flag` (T1 defect, estimated medium): 204,127 to 573,120 of 200,000; accepted at 5,000 or less a pass.
26. `records-plan-apply`, `bench-skip-no-code`, `moved-review-diff`, `advisory-findings-auto`, `merge-output-cap`, `scout-prune-step`, `doc-budget-room`, `groom-fold-format`, `merge-main-queue-conflict` (T1, estimated small each).
27. `normal-command-fixes` (T3 Low (6), estimated large): `normal_command_handler.rb:62`.
28. `motions-search-tidy-b` (T4, estimated medium), `plugin-host-tidy`, `input-bytes-tidy`, `frame-presenter-tidy`, `motions-search-tidy-c` (T6, estimated medium each).

## Decisions

- 3 features, 3 backlog (T1, the user's request): `review-lite`, `quality-first-pass`, `contributor-checklist` under the user-approved exception.
- backlog-pick batches 1 to 3 parts a to Pool 2 to 4 (the user's request): `pr-trust-lows` first, Medium (4), Lows (4), (4), (3); each pushed back 1.
- `lsp-tidy` to Sprint 20 (T6, the user's request): pushed back 3, its reason written.
- Split (T1, size rule): workflow rows pipeline-diet-b 1,314,641 and squash-body-full 1,206,650 over; review-lite without `advisory-findings-auto`, quality-first-pass without review-fix-treadmill (to `rework-review-repeat`), contributor-checklist parts b, d to Pool 5.
- Estimate medium (T1): pipeline-diet 912,815, merge-main-path 814,062 at rework 0.
- `test-one-alone` added (T4, the user's request): sign-colors note 16.
- sign-colors retro 12 into `review-lite` (T1): rework 2, 0 blocking, 71,651 output.
- Sweep security (T1), none at confidence 8: Medium (6), (5), Lows (3) placed.
- Overruns (T1): check 311,377 and 325,087 of 200,000; sign-colors 1,231,042, 118.0 min.
- `check-runner-safety` Pool 1, Sprint 20 pipeline-defect slot (T1, the user's rule: no security item pushed back over 3 times, every one fixed): pushed back 19.
