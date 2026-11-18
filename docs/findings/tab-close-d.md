### The contributor returns work the quality review blocks on its first pass (plugin-lazy-activate retro 11)
- Location: `.claude/agents/contributor.md`, the contributor's self-check before it returns; `.claude/workflows/deliver-change.js`, the quality round.
- Why: quality passes first 85 of 153 runs against check 150/153 and security 147/153; plugin-lazy-activate had 2 blocking findings of two kinds (a test expectation edited against plugin-host spec.md:100 and :115 left in force; a new raise branch at plugin_syntax.rb:48 without its test), its rework round 104,027 output tokens, 30 percent of 343,926; lsp-container-b and vim-folds-a also quality:0 in the feature lane's last 10.
- Fix: make the contributor catch these two kinds before it returns, without adding a phase; accepted when status shows quality first passes at 8 or more of the next 10 feature runs and none of these two blocking kinds.

### A scout runs for an area the change barely edits (plugin-lazy-activate retro 12)
- Location: `.claude/workflows/deliver-change.js`, the scout plan from the areas start.
- Why: plugin-lazy-activate spent 57,113 output tokens and 40 calls on scouts (16.6 percent of 343,926 output, 16.5 percent of 242 calls) for 3 packs, one (build-and-ci) for 8 of 813 changed lines; scout shares tab-close-b 25 percent, tab-close 21 percent, secret-patterns 33.6 percent.
- Fix: skip or fold the scout of an area whose planned edit is a few lines; accepted when the scout share of output over the next 10 feature runs has a median at or under 12 percent with first.check and first.quality rates not lower.

### The finder's tab pick repeats the open_file call of its default branch
- Location: carat/plugins/finder/plugin.rb:332 (open_path, the when :tab branch)
- Why: the :tab branch's target == 0 arm repeats the else branch's host.open_file(target, path) inside a ternary, so the default open lives in two places and can drift (two quality advisories, duplication and simplicity, merged here)
- Fix: before the case, map how to the default when it is :tab and target is 0 (or guard so :tab reaches open_as_tab only when target != 0), leaving when :tab to call open_as_tab alone and the zero case to fall through to the one open_file call

### The host's open_as_tab fallback with no file window is reached by no shipped caller
- Location: carat/use_cases/plugins/window_requests.rb:214, docs/plugins.md:79
- Why: every shipped plugin now checks editing_window before open_as_tab, so the host's no-file-window fallback to a tab page is dead for shipped callers, and docs/plugins.md asks each plugin to repeat the check
- Fix: at the next plugin API minor step make open_as_tab with no file window open in the current window as open_file does, and drop the finder's own check

### The finder's <C-t> row leaves out the lone-tree case
- Location: docs/compatibility.md:528
- Why: the explorer's row (line 508) and the file-finder spec state that with no file window the tab open opens as <CR> does, but the finder's <C-t> row omits it, so the table under-describes the behavior
- Fix: append "and with no file window as <CR> opens" to the row

## Findings of tab-close-d after its package step

- quality advisory docs/queue-feature.md:30 docs currency: the merge resolution removed tab-close-d from the Sprint 17 list, but the decision still places tab-close-d and vim-folds-b at places 1 and 2 and vim-line-commands-c third, while the list now has vim-folds-b at 1 and vim-line-commands-c at 2; fix: say tab-close-d merged from place 1, vim-folds-b and vim-line-commands-c now at places 1 and 2
- quality advisory docs/findings/tab-close-d.md:11 one clear way: the three new entries drop the backticks around paths and the trailing periods the file's earlier entries (lines 1 to 10) use; fix: backtick the locations and end each Location, Why, and Fix line with a period as above
