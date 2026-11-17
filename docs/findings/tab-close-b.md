### The explorer's t with no file window opens a tab page holding only the tree
- Location: carat/use_cases/plugins/window_requests.rb:211
- Why: open_as_tab with no file window under option.gt buffers falls back to open_in_tab, so the explorer's t with only the tree left opens tab page 2 and leaves tab page 1 holding only the explorer, the state tab-close-b fixes and that test/editor_tab_flows.rb clean? rejects, while l and Enter open a file window beside the tree; the fallback is also untested (quality advisory, tab-close-b review).
- Fix: under option.gt buffers open a file window beside the tree as open_file_window does for l, or pin the chosen fallback with a test in test/editor_explorer.rb.

### A refused buffer switch from a side window moves the tab page's previous window
- Location: carat/use_cases/buffers/switch_buffer.rb:45
- Why: a refused switch restores the focus with tab.focus(side), which also rewrites tab.previous to the editing leaf instead of restoring its earlier value, so the refusal is not a full no-op on the tab page and a later editing_window may pick another file window (quality advisory, tab-close-b review).
- Fix: save tab.previous before focusing and set it back with the focus on failure, or document that previous moves, with a test in test/editor_buffers.rb.
