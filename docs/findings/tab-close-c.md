### Two definitions of a side window coexist after tab-close-c
- Location: carat/use_cases/files/quit.rb:87
- Why: TabPage#side_window? (a shown slot's window, the one place per the design) now sits beside Quit#beside_side_windows?, TabPage#editing_leaf, and file_window_count, which treat any scratch-buffer window as a side window, so :q counts a reading view or a pinned documentation split as a side window while buffer switches do not.
- Fix: route Quit#beside_side_windows? through TabPage#side_window?, or name the scratch-based notion apart (file window versus side window) in code and docs.

### No flow covers a buffer switch from a pinned documentation split
- Location: test/editor_tab_flows.rb:189
- Why: the design states a behavior change for a PinHover split, which now switches itself instead of the file window, yet only the reading view has flows, so a regression of the pinned split would pass.
- Fix: add one flow row that pins a hover split and runs :bn there, expecting the split to switch and the file window to keep its buffer.
