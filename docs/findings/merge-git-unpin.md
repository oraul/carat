
### merge_main runs git with the global configuration and hooks again

- Location: `tools/run_state.sh`, `merge_main` (the merge, the queue checkout, add, commit, and abort after its fetch), reopened from #328 by the user's decision of 2026-11-23 ("Remove the pinned git only").
- Why it matters: a global or system git configuration or a repository hook (for example a refusing `pre-merge-commit`) can again change or stop the merge of a moved main, and branch code could have planted a hook.
- Fix outline: if the user lifts the decision, restore `pinned_git` on these calls and the two hook cases of #328 in `tools/tools_test.sh`.
none
