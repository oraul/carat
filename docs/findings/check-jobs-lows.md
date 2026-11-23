### The escape scan's changed-path list reaches the terminal unfiltered (Low)
- Location: tools/run_state.sh, check_run, the escaped paths printed with head and sed 's/^/| /'.
- Why: a path changed outside the clone can hold a control byte, so it reaches the terminal as the failing stage's log excerpt did before this change; it is outside this change's outcome.
- Fix: pipe the list through visible_text before the sed, as the excerpt now is, with a tools-test case for a path holding an ESC byte.
none
