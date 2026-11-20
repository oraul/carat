# Queue: backlog

Ordered by `docs/goals.md`; folded findings are in `docs/backlog.md`. Every fix is accepted with `lh` 26.0, `j` 27.0, `insert` 26.0 held.

## Sprint 24

The user-approved exception (2026-11-20, the user's backlog decision): groom-stale-prune runs in the backlog lane, outside the 3.

1. `review-trust-lows` (T1 pipeline defect, security Lows (3) to (6), estimated large, batch 1, area 1, critical a tools/open_pr.sh): Where: `tools/open_pr.sh:118`, `.github/workflows/open-pr.yml:39`, `:48` (actions by tag beside PR_TOKEN), fork pull requests sharing a branch name; `.claude/workflows/sprint-planning.js:97`, `:123`, `:218`; `tools/gates.sh:112`, `tools/run_state.sh:201`. Why: 7 security Lows. Fix outline: split at its start, the `tools/gates.sh:112` list first, alone. Accepted when a test per heading fails before the fix. Backlog: "## A security review after a quality-only fix reads the whole branch again", "## The review continuations run one after the other", "## Security Lows of the periodic review at 186ddfb", "## A security review stays current after later instruction-file commits", "## pr-on-push security Low at tools/open_pr.sh:118", "## pr-on-push security Low at .github/workflows/open-pr.yml:39", "### Sprint security continuation drops differently spelled unreviewed files (`sprint-planning` security Low (5))", "### The sprint quality review gets no continuation at its cap (`sprint-1` review quality)", "### Restrict the open-pr edit path to same-repository pull requests (security Low, confidence 4)", "### Fork pull requests sharing the branch name block open_pr.sh (security Low (5))", "### open-pr pins its actions by tag beside PR_TOKEN (security Low, confidence 6)".
2. `render-tidy` (T3 security Low (5), estimated large, batch 2, area 13, critical a carat/adapters/screen_presenter.rb): Where: `screen_presenter.rb:30` (a pasted ESC runs commands); `decoded_line.rb`, `frame_presenter.rb` `paint_text`; `display_width.rb:54`; `frame_presenter.rb:569`, `:382`, `:758`, `:1064`, `:201`; `test/adapters_screen_presenter.rb:318`; `start_art.rb:167`. Why: 1 security Low, 2 visible bugs, 7 tidies. Fix outline: split at its start, the paste first. Accepted when a test per heading fails before the fix, a pasted ESC and colon insert literally, and `lh` held. Backlog: "### Bracketed paste is never enabled (sprint-14 sweep security Low (5))", "## Illegal bytes are drawn as U+FFFD, not as hexadecimal markers", "## code_of decodes UTF-8 inside DisplayWidth", "## Match highlighting walks matches left of the scroll and keeps rows painted after the budget stopped", "## FramePresenter passes the painted row through instance variables", "## The screen presenter's first painted row test accepts two outputs", "## FramePresenter clears the layout twice for the hit-enter prompt and the start screen", "## StartArt#paint clamps a step no caller passes out of range", "## StartArt.from_plain bends the from_x naming", "## DisplayWidth.of_char has no caller".

## Pool

1. `drivers-lsp-lows` (T3 security Lows (3), (5), (4), estimated large, pushed back 1, batch 3, area 17, critical a carat/drivers/disk_files.rb): batch 3, 10 headings: `disk_files.rb:33`, `:57`, NO_COLOR, `process_runner.rb:58`, `json_rpc_language_gateway.rb:1059`.
2. `plan-apply-stale` (T1 pipeline defect, estimated small, critical b tools/run_state.sh): #263 replaced 7e3d400's backlog queue with one planned before it, losing 5 items (8715 to 8768 bytes). Accepted when a tools-test case fails before the fix: a plan older than its queue's last commit no longer replaces it.
3. `check-lane-scratch` (T1 pipeline defect, estimated small, pushed back 1, critical b tools/run_state.sh): another lane's logs refused 2 checks (picker-styles-b notes 7, 8, 10). Backlog: "### A concurrent lane's benchmark log fails another lane's check".
4. `skill-guard` (T1 defect, Medium (6), estimated small, pushed back 2, critical a tools/agent_guard.sh): `agent_guard.sh:1071`.
5. `lane-name-guards` (T1 pipeline defect, security Low (4), estimated small, pushed back 2, critical a tools/run_state.sh): `run_state.sh:3397`. Backlog: "### Lane worktree trusts a branch-controlled build/pipeline", "### Merger's lane-close and contributor's merge-main accept any change name".
6. `groom-findings-refs` (T1 pipeline defect, estimated small, pushed back 2, critical a tools/run_state.sh): folded entries name deleted findings files, 1 hand edit; `run_state.sh:489`. Backlog: "### Two security entries stay open though #214 fixed them".
7. `records-bench-skip` (T1 pipeline efficiency, estimated small, pushed back 2, critical b .claude/workflows/deliver-change.js): bench 11.6 to 21.4 percent of output, a stale `grep` base (picker-styles-b note 11).
8. `budget-recalibrate` (T1, estimated small, pushed back 3, reason: the user's exception order, critical b tools/run_state.sh): small records rows 983,348 and 2,599,323, an overrun note read 0 total (picker-styles-b note 9); a resumed run 0 output on 51 of 230 calls (project-config-guards note 6).
9. `closing-loop-fold`, `merge-wait-bound` (T1 pipeline efficiency, estimated small each, pushed back 1, critical b .claude/workflows/deliver-change.js): advisory-only rounds 4 runs in a row (syntax-tidy note 3), a rerun check 25.1 percent of output (status-winbar-tabs note 8); merge waits 30 to 32 percent.
10. `merge-body-check`, `check-runner-safety-bench`, `push-merge-guards`, `check-runner-safety-b`, `plan-needed-reviews` (T1 defects, estimated medium each, pushed back 3, same reason, critical b tools/run_state.sh): push-merge-guards adds contributor-tier-medium note 6; "### plan-needed names only the first failing review while merged_since clears every one before the planner's time".
11. `check-at-head`, `self-found-fix`, `plan-queued-lite`, `scout-prune` (T1 pipeline efficiency, estimated small each, pushed back 1, critical b .claude/workflows/deliver-change.js): scouts 50 of 196 calls (syntax-tidy note 2), 35 of 230 on a split-off area (project-config-guards note 7).
12. `split-proof`, `contributor-rule-ten` (T1 pipeline efficiency, estimated small each, critical b .claude/agents/planner.md): a split part changed no row, 182285 output (status-winbar-tabs note 6); rule 10 skipped, 5 advisories (its note 7). Accepted when each split part names a row failing at the split commit, and rule 10 goes or binds.
13. `arch-doc-budget` (T1 pipeline efficiency, estimated small): `docs/architecture.md` at 88062 of 88064 bytes, a trim drew 1 advisory (project-config-guards note 5). Accepted when the next addition there deletes no unrelated fact.
14. `use-case-surface-c`, `-d` (T2 user request, estimated medium each, pushed back 4, reason: the waves first).
15. `ex-commands-tidy-b` (T4, estimated medium, pushed back 1): "## Ex ranges resolve no arithmetic, pattern, or other mark", "## ExRange keeps a given member no caller reads", "## OpenFile asks the port about a path twice", "## File operations check containment and act in separate calls", "## Every test run builds two 64 MiB strings".
16. `visual-star-selection` (T5 Neovim compatibility, estimated small): `input_controller.rb:96`. Backlog: "## Visual star and hash search the word, not the selection".
17. `tokenizer-languages` (T5 roadmap, estimated medium, feature lane): "## Only Ruby has a tokenizer".
18. `project-config-tidy` (T6 advisories, 5, estimated medium, critical d carat/domain/config.rb): "## Config predicates note problems and repeat the none word", "## Spinel drops appends to an empty array literal passed to a method", "## The background option's values are bare literals", "## Two classes declare a collaborator twice or by hand", "## The generated config header names spin run, and the write step is copied".

## Decisions

- Security first (T0): none; sprint-18 security Medium (9) `run_state.sh:449` at 53b1e58e8eae fixed by b5b0aec (#214), ancestor of 3af2fc9099f3; Low (3) `:2648` 0 matches.
- Delivering (T1 user request): groom-stale-prune by the exception of 2026-11-20, outside Sprint 24's 3 (1 of 3 delivered).
- Size (T1): medium; groom rows 995,203 and 1,444,297; last two rows 1,311,158 large and 1,518,601, not both over.
- Split (T1): none; 2 testable parts, under 3; no `tools/rules.sh` edit.
- Critical (a): `tools/run_state.sh`, groom's security guard.
- Not folded (T1): groom-findings-refs, as the brief keeps to exactly this.
- Restored (T1 defect): 7e3d400's Sprint 24 items 2, 3, Pool 1, 2, 11 (#263 dropped them); Pool 2.
- Placed (T1): project-config-guards notes 5, 6, 7 to Pools 13, 8, 11; status-winbar-tabs 6, 7, 8 to 12, 12, 9.
- Moved (T5): set-options, theme-tuning, semantic-highlight are feature Pool 17.
- Aging: the exception passes the Pool, each pushed back 1, two at 3.
