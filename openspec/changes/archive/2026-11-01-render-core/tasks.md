# Tasks

## 1. Benchmark first

- [x] 1.1 Add `bench/keys.rb` (the eleven scenarios over `carat/test_support.rb`) and `bench/run.sh` (allocations per key from two `SPINEL_ALLOC_REPORT` runs, pinned to one core, `--budget`), and the `bench`, `bench-budget`, and `profile` targets of the `Makefile`; verify by measuring 0978d16 with `make bench` before any other change and keeping that binary for the comparison

## 2. Domain: frames and decoded lines

- [x] 2.1 Add `carat/domain/utf8.rb` (byte-walk decoding of one code point), `carat/domain/decoded_line.rb`, `carat/domain/identity_table.rb`, and `carat/domain/line_cache.rb`; verify with the new `test/domain_line_cache.rb` (decoding ASCII, UTF-8, tabs, controls, and malformed bytes, display columns, a hit by identity, a copy of a line missing, eviction after two turns, an edited line decoded again, a tabstop change)
- [x] 2.2 Rewrite `carat/domain/frame.rb` over flat `Array[Integer]` cells with the dirty, source, scroll, serial, and layout members, keeping `Cell` as an on-demand view in `carat/domain/cell.rb`; verify with the new `test/domain_frame.rb` (put, wide characters at the edge, the C1 escapes stored as U+FFFD, numbers, blanks, resize by reallocation, row comparison) and the existing frame rows of `test/adapters_frame_presenter.rb`
- [x] 2.3 Make `DisplayWidth.column` and `col_at` walk bytes, `Walker` classify code points, and `Buffer#first_nonblank` and `indent_of` compare bytes; verify with `test/domain_selection.rb`, `test/domain_motions.rb`, `test/editor_motions.rb`, and new rows for UTF-8 lines in `test/domain_line_cache.rb`

## 3. Use cases: ArrangeView

- [x] 3.1 Add the screen size to `carat/domain/editor_state.rb` and `carat/use_cases/arrange_view.rb`; run it from `carat/use_cases/handle_key.rb` after every key step and after the plugins observe, and from `carat/adapters/editor_assembly.rb` after opening and before every render; verify with the new `test/use_cases_arrange_view.rb` (arrangement, tab line, scrolling both ways, nothing at size 0, two splits with no render between them, `H` after a jump with no render between) and `test/adapters_assembly.rb` (the cache is one object)

## 4. Adapters: presenters

- [x] 4.1 Rewrite `carat/adapters/frame_presenter.rb` as `call(state)` over two frames, the line cache, and `carat/adapters/painted_rows.rb`, with dirty rows and scroll detection; verify with `test/adapters_frame_presenter.rb` (moved to arrange first, every existing row unchanged) and the new `test/adapters_dirty_rows.rb` (a cursor move dirties the rows it left and entered and the status line, an edit dirties its rows, a message dirties the message row, a scroll records its region and sources, a split window does not scroll)
- [x] 4.2 Rewrite `carat/adapters/screen_presenter.rb` to write changed runs, scroll regions, and the fallbacks; verify with `test/adapters_screen_presenter.rb` (changed runs, joined runs, wide characters, scroll up and down, a window beside another, the first frame after a resize, a frame presented twice, a frame not presented)
- [x] 4.3 Keep `EditorAssembly#render(rows, cols)` the one render path of `bin/carat.rb`, `carat/doubles/editor_harness.rb`, and the benchmark, now storing the size and running `ArrangeView`; verify with every `test/editor_*.rb` snapshot unchanged and `test/smoke_editor.rb`
- [x] 4.4 Remove the per-key allocations outside the presenters listed in the design (`carat/domain/window.rb`, `keymap_node.rb`, `buffer.rb`, `layout.rb`, `carat/use_cases/plugins/plugin_events.rb`, `carat/adapters/key_decoder.rb`); verify with `test/domain_buffer.rb`, `test/domain_edits.rb`, `test/domain_keymap.rb`, `test/adapters_key_decoder.rb`, `test/use_cases_plugins.rb`, and the allocation counts of `make bench`

## 5. Checks, measurements, and documentation

- [x] 5.1 Run `make snapshots` and review the diff: only the new tests and the screen presenter's bytes may change; verify by reading the diff
- [x] 5.2 Check `make types` for every frame, cache, and painted-row member and keep `make diagnose` clean; verify by the command output
- [x] 5.3 Measure 0978d16 and the branch with the benchmark, pinned to one core, interleaved, medians, against every target; verify by the numbers recorded in the design
- [x] 5.4 Run `make bench-budget` from `.github/workflows/ci.yml` after the tests; verify locally (26 objects per key against 100) and on the pull request's CI run
- [x] 5.5 Update `CLAUDE.md` (Commands for `make bench`, `make bench-budget`, `make profile`; Layout), `docs/architecture.md` section 8.2, section 11, and the rendering row of section 13, and remove the scrolling entry from `docs/backlog.md`, adding any finding left for later; verify by reading the docs against the code

## Workflow follow-up

- Run the security review on the committed branch, archive the change, open the pull request, wait for CI, and squash-merge.
