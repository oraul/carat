### The tab mark under a focused float
- Location: `carat/adapters/tab_bar.rb`, `selected_buffer`
- Why: a focused float, such as the finder, is `state.window`, so its scratch buffer leaves no tab selected, as the explorer's did before this change; the brief asks for sidebars only.
- Fix: while a float has focus, select the tab of the layout window (`TabPage#layout_window`) in `selected_buffer`, with a test that focuses a float over a file window.
