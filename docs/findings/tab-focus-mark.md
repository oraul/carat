### The tab mark under a focused float
- Location: `carat/adapters/tab_bar.rb`, `selected_buffer`
- Why: a focused float, such as the finder, is `state.window`, so its scratch buffer leaves no tab selected, as the explorer's did before this change; the brief asks for sidebars only.
- Fix: while a float has focus, select the tab of the layout window (`TabPage#layout_window`) in `selected_buffer`, with a test that focuses a float over a file window.
### The package phase cost 45,250 output tokens in 10 calls with no CI fix (one-accent-tabs retro note 8)
- Location: `.claude/workflows/deliver-change.js` package step
- Why: committing the pull request text and pushing took 18 percent of the one-accent-tabs run's output, against 10,185 in 26 calls for bench-skip-nonruby; near the backlog lane's `package-one-start` item.
- Fix: with no CI fix the package phase stays under 15,000 output tokens, or the run notes name the cause (a resume past the push rerunning the check and reviews); merge into `package-one-start` when a sprint draws it.
