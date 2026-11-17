### The merger reports the branch head instead of the squash commit (vim-line-commands-b retro)
- Location: `.claude/agents/merger.md`, the merge phase of `.claude/workflows/deliver-change.js`
- Why: vim-line-commands-b's merger reported f230c3210a53 as the merged commit while main's squash commit was 25604e0ec359 (its merge-disagreement note 9), after record-squash-commit merged; the workflow's check recorded the right commit, so only the cross-check stands between a wrong head and the history's merged column.
- Fix: the merger reads the merged commit from the pull request's merge commit field (or main's first-parent commit naming the pull request number); accepted when a tools-test case or the next 3 merges record no merge-disagreement note.

### make test-one does not compile test/use_cases_plugins.rb at 95bf2e04c258 (git-signs-transport retro)
- Location: `test/use_cases_plugins.rb`, `make test-one`
- Why: git-signs-transport's contributor found `make test-one T=test/use_cases_plugins.rb` failing to compile at main 95bf2e04c258 while the full runner passes, so the one-file path a contributor uses to iterate is broken for the plugin host's largest test (retro note 7).
- Fix: find what the file relies on that only the whole runner supplies and make it self-contained; accepted when `make test-one T=test/use_cases_plugins.rb` passes at main.
