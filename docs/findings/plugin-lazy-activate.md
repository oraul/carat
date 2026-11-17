### make test-one does not compile test/use_cases_plugins.rb
- Location: test/use_cases_plugins.rb through carat/use_cases/history/list_undo.rb:27 and carat/use_cases/history/walk_history.rb:168
- Why: `make test-one T=test/use_cases_plugins.rb` still fails at 25604e0ec359 with "void value not ignored as it ought to be" in the generated C, so the plugin host's main test runs only inside the full runner; a contributor iterating on the plugin host waits about three minutes per change instead of one.
- Fix: make `ListUndo#call` and `WalkHistory#finish` return a typed value on every path (or not use the void result), then confirm test-one compiles the file on its own.

### A filetype plugin activated while highlighting is arranged and delivered only on the next key (plugin-lazy-activate quality)
- Location: carat/use_cases/plugins/plugin_syntax.rb:48, carat/use_cases/docs/format_docs.rb:56
- Why: a filetype trigger activates the plugin from HighlightView inside EditorAssembly#render, after ArrangeView and outside any PluginHost flush, so windows, a segment, or events the plugin's activate causes are neither arranged nor delivered until the next key; FormatDocs also activates it from hover docs, a trigger the plugin-host spec ("a buffer of its filetype is highlighted") does not name.
- Fix: activate filetype providers in PluginHost#resized, before arrange and then flush, for the visible buffers' syntaxes, and keep the provider a pure lookup.

### The git-status spec still says the segment shows on activation before any buffer opens (plugin-lazy-activate quality)
- Location: openspec/specs/git-status/spec.md:34, openspec/specs/plugin-host/spec.md:387
- Why: the scenario "The segment shows on activation" stays in the main spec though git_signs now activates only after the first frame and test/editor_git_signs.rb replaced its test with "Git runs only after the first frame"; the binding-conflict requirement still says "a plugin activated before it" while conflicts are now decided at prepare_all.
- Fix: add a git-status delta that removes or modifies the scenario, and reword the conflict requirement to "prepared".

### The hello plugin's opened count is always 1 at activate and misses earlier buffers (plugin-lazy-activate quality)
- Location: carat/plugins/hello/plugin.rb:49
- Why: read_buffer(0) resolves the current buffer, which always exists, so the ternary is a dead branch always giving 1, and buffers opened before the first greeting other than the current one are not counted (":e b.txt" then hh from a.txt reads "1 buffer opened").
- Fix: write "@opened = 1" with a comment saying it counts the current buffer, or count the listed buffers at activate if a host request offers them.
### test/use_cases_plugins.rb did not compile alone at 95bf2e04c258
- Location: `test/use_cases_plugins.rb`, `make test-one T=test/use_cases_plugins.rb` (git-signs-transport retro note 7).
- Why: the plugin host's own test file could not be run alone on the base, so a plugin host change is checked only through the whole runner; the contributor reported it and nothing recorded it.
- Fix: make the file compile alone in `make test-one`; accepted when `make test-one T=test/use_cases_plugins.rb` passes on main.

### vim-line-commands-b's quality advisories reached main unrecorded
- Location: `docs/compatibility.md:332` (the Substitute section's opening sentence pasted inside itself), `carat/domain/ex_range.rb:151` (`.5`, `$ 1`, `. 5` answer E16 where Neovim reads an implicit offset, untested), `carat/domain/ex_range.rb:101` (resolve re-reads the error text against UNREAD), `docs/codebase-map.md:128` (Messages entry lacks E477 and REPORT; RegisterCount lacks parse_count).
- Why: the package step fixed 2, the push gate refused, it reverted them (653eefe) and appended 1 of 4 to docs/findings (vim-line-commands-b retro note 5).
- Fix: rewrite the sentence as one; treat an address base followed by digits or blanks as unread, with a `domain_ex_range` row for `.5d`; call `unread?` directly; name the 3 symbols in the map. Skip any part already in `docs/findings/vim-line-commands-b.md`.

### The package step reverts advisory fixes and drops their findings (evidence for package-advisory-edit)
- Location: the package step of `.claude/workflows/deliver-change.js`; vim-line-commands-b retro note 5.
- Why: package 10,126/23 against the feature median of 15 calls; quality 4 advisories, 1 appended; third run after motions-search-tidy 16,259/22 and record-squash-commit 38,843/17.
- Fix: fold into backlog pool item `package-advisory-edit`; accepted when over 3 runs with advisories each one not fixed at the reviewed commit is in docs/findings and no revert commit is on the branch.

### The check-pass budget line converts output at a fixed 6 per token
- Location: the check-pass budget line of `.claude/workflows/deliver-change.js`; vim-line-commands-b retro note 6.
- Why: it noted 197,007 output as 98.5 percent of medium while the run closed at 893,872 total of 1,200,000; the last 10 feature rows' total to output ratio runs 2.42 to 7.94, so the line notes overruns the totals never show and changes no decision.
- Fix: drop the line, or make its over agree with the final total-token budget line on the last 10 medium feature rows.

### The planner runs on a placed first item (evidence for plan-skip-placed)
- Location: the plan phase; git-signs-transport retro note 8, vim-line-commands-b retro note 7.
- Why: plan 22,923/10 (11.4 percent of output) and 21,821/10 (8.1 percent), after secret-patterns 11,077/12, 3 runs whose decisions kept the item as written.
- Fix: fold into backlog pool item `plan-skip-placed`; accepted as that item states.

### The merger exceeds its medium call cap waiting on CI (evidence for merge-cap-ci-wait)
- Location: the merger's cap in `CALL_CAPS`; vim-line-commands-b note 8.
- Why: merge 14 calls over its cap of 12, after secret-patterns 16 over 14.
- Fix: fold into backlog pool item `merge-cap-ci-wait`.

### The merger reports the branch head as the merged commit
- Location: the merger's result and the merge record of `tools/run_state.sh`; vim-line-commands-b note 9.
- Why: it reported f230c3210a53, the branch head, not the squash commit 25604e0ec359, which the fallback recorded instead; a record that trusted the report would point at a commit absent from main.
- Fix: the merger reports the squash commit read from main's log; accepted when a tools-test case shows a branch head refused as the merged commit.

### The planner weighs quality-advisory notes the package step handled
- Location: the planner's input from `sh tools/run_state.sh show`; git-signs-transport retro note 6.
- Why: git-signs-transport 5 advisories (1 kept as a finding, 0 changed code) and secret-patterns 4, all 4 given a not-placed decision; quality first pass 83/151.
- Fix: leave handled `quality-*` notes out of what the planner reads; accepted when the next planner's decisions carry no line about them while a kept advisory still reaches docs/findings.

### A base defect a contributor names is not recorded
- Location: the contributor's return and docs/findings/CHANGE.md; git-signs-transport retro note 7.
- Why: 1 base defect reported (the test file above), 0 recorded.
- Fix: the contributor appends a named pre-existing defect to its findings file; accepted when the next such defect appears there.
