# Queue: backlog

Ordered by `docs/goals.md`; folded findings are in `docs/backlog.md`. Every fix is accepted with `lh` 26.0, `j` 27.0, `insert` 26.0 held.

## Sprint 19

The user-approved exception (2026-11-18): pipeline speedups, not defects, in this order. Evidence: 0 rework rounds take 37-43 min, 2-3 rounds 70-95 min; 496 of 529 findings in the last 45 runs were advisory.

1. `quality-first-pass` (T1 pipeline, user request, estimated medium): quality passes first 94 of 169 runs against check 165/169 and security 162/169; the reviewer is told to report every blocking finding in a first pass (`.claude/agents/quality-reviewer.md:21`), yet later rounds still raise new ones on code the first pass read, and only a re-raise at an earlier advisory's location is caught (`deliver-change.js:1110`). Fix outline: the first pass reports every finding it can; a later blocking finding on lines unchanged since the first pass is recorded as a first-pass miss. Accepted when a workflow test case notes such a finding as a first-pass miss, and quality passes first on 7 of the next 10 runs. Backlog: "### Quality fails its first pass on about half the runs".
2. `contributor-checklist` (T1 pipeline, user request, estimated medium, parts a and c): quality fails first on 75 of 169 runs from findings a checklist catches (plugin-lazy-activate: a stale test expectation, a raise branch untested); the self-check (`.claude/agents/contributor.md:38`) names no edge case. Fix outline: a checklist from real findings (empty range, CRLF, UTF-16 and multi-byte, trailing blanks, last line, empty buffer; a test per behavior change; search for an existing helper before writing; comments, docs, and spec text match the code), and the contributor self-reviews its diff with the quality reviewer's instructions before returning, within contributor.md's budget. Accepted when contributor.md's self-check names each of those points and the self-review, docs-lint budgets hold, and quality passes first on 8 of the next 10 runs. Backlog: "### The quality review fails its first pass most often, and its round costs most (plugin-lazy-activate retro)", "### The contributor returns work the quality review blocks on its first pass (plugin-lazy-activate retro 11)".

## Pool

1. `check-runner-safety` (T1 defect, Medium (6), estimated medium, pushed back 19, Sprint 20 pipeline-defect slot, the user's rule): 3 headings; reviewers run the branch's Makefile (`agent_guard.sh:590`, sweep Medium (5)).
2. `review-lite-docs` (T1 pipeline, user request, estimated small, after `review-lite`): main's merge gate counts a pass settled only over a records-only diff (`tools/gates.sh:119`, `:359`, `:449`), so `review-lite` skips the check and the security review only on a round whose fix diff is records-only; an advisory round editing README.md or docs/architecture.md still runs both. Fix outline: settled_at also accepts the documentation paths of `tools/rules.sh:78`, its own change first (the merge gate rule). Accepted when tools-test cases settle a pass over a README-only diff and refuse one over a `carat/` comment (Spinel `#:` signatures) or a test.
3. `pr-trust-lows` (T1 pipeline defect, security Medium (4), Lows (4), (4), (3), estimated medium, pushed back 1, batch 1 part a): `tools/spec_validate.sh:17`, `tools/open_pr.sh:118`, `:190`, `open-pr.yml:39`; "## OpenSpec runs unpinned beside the push credentials (sprint-2 sweep security Medium (4))", "## pr-on-push security Low at tools/open_pr.sh:118", "## pr-on-push security Low at .github/workflows/open-pr.yml:39", "### Restrict the open-pr edit path to same-repository pull requests (security Low, confidence 4)".
4. `render-tidy` (T6 with security Low (5), estimated medium, pushed back 1, batch 2 part a): `screen_presenter.rb:30`, `frame_presenter.rb:569`, `:382`, `:201`; "### Bracketed paste is never enabled (sprint-14 sweep security Low (5))", "## Match highlighting walks matches left of the scroll and keeps rows painted after the budget stopped", "## FramePresenter passes the painted row through instance variables", "## FramePresenter clears the layout twice for the hit-enter prompt and the start screen", "## The screen presenter's first painted row test accepts two outputs".
5. `file-access-color` (T3 security Lows (3), (3), estimated medium, pushed back 1, batch 3 part a): `disk_files.rb:33`, `:57`, `rc_config_gateway.rb:59`, `editor_assembly.rb:489`; "### MakePath and the project .caratrc check follow a link swapped after the probe (sprint-14 sweep security Low (3), Low (3))", "## DiskFiles#stat makes four system stats per path", "## NO_COLOR leaves syntax, bars, and messages colored", "## No test reads NO_COLOR through AnsiTerminal".
6. `lsp-tidy` (T6 with Lows (5), (4), (3), estimated medium, Sprint 20 by the user's request, pushed back 3, reason: the user's request, at the limit of 3): `process_runner.rb:55`, `:124`, `json_rpc_language_gateway.rb:205`, `:430`, `:789`; its 7 Sprint 18 headings.
7. `contributor-checklist-b` (T1 pipeline, user request, estimated small, parts b and d, after `doc-budget-room`): a finding repeated 3 or more times becomes a lint or gates check; the planner's brief names the area's edge cases (planner.md 8,179 of 8,192).
8. `test-one-alone` (T4, user request, estimated small): `make test-one T=test/use_cases_plugins.rb` does not compile alone on main, void-value errors in `carat/use_cases/history/list_undo.rb`, `carat/use_cases/history/walk_history.rb`, `carat/use_cases/dispatcher.rb` (sign-colors note 16); accepted when it compiles and passes alone.
9. `lsp-tidy-b` (T6 with Lows (5), (4), estimated medium, batch 3 part b): "## A save while the language server starts is never sent", "## The language server outbox has no bound", "## Published diagnostics keep any number of URIs", "## The gateway's apply has an unclear name and a needless branch", "## ControlText.cleaned is public with a flag argument", "## The published helper's comment in the LSP test is wrapped unevenly".
10. `render-tidy-b` (T6, estimated medium, batch 2 part b): "## Illegal bytes are drawn as U+FFFD, not as hexadecimal markers", "## code_of decodes UTF-8 inside DisplayWidth", "## DisplayWidth.of_char has no caller", "## StartArt#paint clamps a step no caller passes out of range", "## StartArt.from_plain bends the from_x naming".
11. `skill-guard` (T1 defect, Medium (6), estimated small): the agents' Skill tool is in no hook matcher (`tools/agent_guard.sh:1071`).
12. `explorer-tidy` (T6 with a bug, estimated medium, pushed back 5, reason: backlog-pick first): `plugin.rb:516`; 10 headings.
13. `vim-compat-fixes` (T6 bugs, estimated medium): count overflow (`command_grammar.rb:98`), `ci"` on `""` (`text_objects.rb:356`), `{` at 0,0 (`motions.rb:550`), `\V[` (`vim_pattern.rb:134`).
14. `bench-scenarios` (T4, estimated small): 4 scenarios skipped (`bench/run.sh:73`).
15. `glyph-audit` (T2 user request, estimated small): 5 glyphs mean two things each.
16. `sprint-review-continuation` (T1 defect, Low (5), estimated medium): `sprint-planning.js:104`, `:175`; 2 headings.
17. `backlog-throughput-b` (T1, user request, estimated medium): +35 headings a sprint.
18. `round-limit-resume`, `open-pr-retry`, `pr-testing-truth`, `stage-clean` (T1 defects, estimated small each).
19. `rework-review-repeat` (T1, estimated medium, with review-fix-treadmill): later rounds repeat notes and block on each fix round's code (1, 3, 1, 1, 833,080 output); "### A re-review re-raised an advisory declined for the brief's reason"; 2 review-phase headings.
20. `spinel-bump` (T2 user request, estimated medium): 656 commits behind.
21. `check-clone-toolchain`, `periodic-clear-rules` (T1 defects, Medium (6), estimated medium each, pushed back 2): 4 and 7 headings.
22. `review-scope-pins` (T1 defect, Medium (4), estimated medium): 4 headings.
23. `sprint-security-b` (T1 defect, Lows, estimated medium, with batch 1 part b): `tools/gates.sh:112`; "## A security review after a quality-only fix reads the whole branch again", "## The review continuations run one after the other".
24. `ci-trust-gaps-b`, `ci-trust-gaps-c` (T1, Lows, estimated medium): 10 headings; `ci.yml:54` (sweep Low (3)).
25. `toolchain-clean-scope` (T1 defect, estimated small): `Makefile:203`.
26. `check-pass-budget-flag` (T1 defect, estimated medium): 204,127 to 573,120 of 200,000; accepted at 5,000 or less a pass.
27. `records-plan-apply`, `bench-skip-no-code`, `moved-review-diff`, `advisory-findings-auto`, `merge-output-cap`, `scout-prune-step`, `doc-budget-room`, `groom-fold-format`, `merge-main-queue-conflict` (T1, estimated small each); sprint-18-records retro: groom output failed docs-lint, first.check=0 at 399adffe0be5, to `groom-fold-format`; groom-output advisories took rework 2 at 0 blocking, reviews=25498/34, to `advisory-findings-auto`; bench=4721/14 with no `carat/` file to `bench-skip-no-code`.
28. `normal-command-fixes` (T3 Low (6), estimated large): `normal_command_handler.rb:62`.
29. `motions-search-tidy-b` (T4, estimated medium), `plugin-host-tidy`, `input-bytes-tidy`, `frame-presenter-tidy`, `motions-search-tidy-c` (T6, estimated medium each).

## Decisions

- `review-lite` delivered (T1, the user-approved exception of 2026-11-18): Sprint 19 backlog item 1, its 3 headings listed; sign-colors rework 2 at 0 blocking, 71,651 output.
- Security first (T0), none open: sprint-18 periodic security Medium (9) `tools/run_state.sh:449` and Low (3) `:2648` fixed by b5b0aec (#214).
- Estimate medium (T1): pipeline-diet 912,815 in 41.2 min, squash-body-full 1,206,650, pipeline-diet-b 1,314,641; only sign-colors 1,231,042 of the last two over, no size up.
- Merge gate (T1, plan rule): main's settled_at accepts records-only diffs (`tools/gates.sh:121`), so `review-lite` skips only over those; widening to README and docs is `review-lite-docs`, Pool 2, its own change first.
- Overrun (T1): sprint-18-records 2,636,747 of 2,500,000 total, 62.0 min, rework 2 at 0 blocking.
- sprint-18-records retro 11 to 13 (T1) into Pool 27: `groom-fold-format`, `advisory-findings-auto`, `bench-skip-no-code`.
