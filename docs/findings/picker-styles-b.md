### A tokenizer's token length reaches the painter uncut
- Location: carat/use_cases/plugins/plugin_syntax.rb `copied_tokens` and carat/adapters/frame_presenter.rb `paint_tokens`
- Why: `copied_tokens` keeps any length of 1 or more, and `paint_tokens` adds it to the start column before cutting at the line's size, so a plugin token with a length near the integer limit makes that sum overflow if Spinel's integers are fixed width; `style_float` cuts its span lengths to `LONGEST_SPAN` for this reason, the tokenizer path does not.
- Fix: cut the length in `copied_tokens` (or compare `from + length` as `length > size - from` in `paint_tokens`), with a test of a token whose length is 1 << 40.

### The palette's PmenuExtra token may give an end column as its length
- Location: carat/use_cases/discovery/follow_palette.rb `styles`, the `tokens << char_count(line, Domain::DisplayWidth.bytes_within(line, room + NAME_WIDTH))` line
- Why: a `SyntaxLine` token is (start column, length, group), but this pushes the column where the name's column ends, so the run reaches past the name into the key column, which would then draw in PmenuExtra; no test reads a key cell's group.
- Fix: push that end column less `from` as the length, and add a palette test reading a key cell's group.

### A concurrent lane's benchmark log fails another lane's check
- Location: `tools/run_state.sh` `escaped_paths` (`main_scan`) and `.claude/agents/benchmark.md` step 1
- Why: the check of picker-styles-b at 70f84e685dbd passed every stage but was refused because `build/scratch-base-build.log` appeared in the main checkout during its window; the file was written by another lane's benchmark agent redirecting its `make -C tmp/.base` output there, not by any stage, so a parallel delivery turns a clean check into a failed round.
- Fix: have the benchmark agent write its base logs under `tmp/.base/build/` (and the guard refuse a redirection into the main checkout's `build/`), or let `main_scan` skip ignored paths another lane's agent owns, with a tools test for each.

### Check refused on another lane's scratch logs in the shared build directory
- Location: tools/run_state.sh escaped_paths (main_scan of the main checkout's build/), check of picker-styles-b at 272ead28c383
- Why: an agent of the concurrent lane metrics-header-fix redirected its make output to build/scratch-lane-build.log, scratch-lane-metrics.log, scratch-base-build.log, and scratch-base-measure.log in the main checkout while this check ran, so every passed stage was discarded as an escape though no stage wrote them, costing a fix round with no code to change.
- Fix: have agents write scratch output under their own lane or the session scratchpad, never the main checkout's build/, or have escaped_paths ignore files whose writer is outside the check's process tree (for example by scanning only paths the stages can reach, or by refusing only with a stage's pid recorded).
