# Proposal

## Why

A substitute builds each replacement before it charges the work budget for it, so `:s/.*/&&&&/` on a 64 MiB line of an untrusted file builds a 256 MiB string, and a replacement of many `&` a string of gigabytes, before the budget stops the command (security Low (6), `substitution.rb:44`). `OpenFile` asks the file port about a path twice, `exist?` and then `stat` through `ProbePath`, so the two answers can disagree: a dangling link is "absent" to the first and opens as a new buffer, whose write would follow the link out of the tree, while `MakePath` already calls the same entry an existing one (`open_file.rb:45`). Every run of `test/editor_cmdline.rb` builds two 64 MiB strings to put a file over and at the open limit (`test/editor_cmdline.rb:155`). The create of `MakePath` and the other file operations still check containment and act in separate calls (security Low (5), `make_path.rb:47`, `:49`, `resolve_inside.rb:28`); closing that needs a descriptor-relative open (openat), which neither the pinned Spinel nor Ruby's core offers, so it is recorded, as the brief allows. Outside the roadmap order: backlog items of the substitute and the file operations that roadmap items already delivered (`docs/architecture.md` section 12).

## What Changes

- `Substitution.line` charges the size of each replacement, counted by the new `Replacement.size` without building it, before `Replacement.expand` builds it, and stops without building when the budget cannot pay; a recased replacement whose size differs is charged or refunded the difference after the build, so the total stays one charge per character.
- `OpenFile#call` asks the port once, through `ProbePath`, and takes `exists` from that answer; a dangling link is therefore refused with `"path" is not a file`, as a FIFO is, instead of opening as a new buffer.
- `MemoryFiles` gains `pad(path, bytes)`, a file whose size counts bytes its text does not hold, and `dangling(path)`, a link whose target is missing as the driver reports it; `test/editor_cmdline.rb` puts the files over and at the limit with `pad` and builds no 64 MiB string.
- The openat gap (the three file-operation headings) is appended to `docs/findings/files-ex-lows.md` with its fix outline.
- Docs: `docs/compatibility.md` (`:e` row and the Differences paragraphs of the files and substitute sections), `docs/codebase-map.md` (`replacement.rb`, `substitution.rb`, `open_file.rb`, `memory_files.rb`), README's `:e` sentence.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `substitute`: MODIFIED requirement "Untrusted patterns and replacements are bounded" (a replacement is charged before it is built; scenario "A replacement past the budget is never built").
- `command-line-mode`: MODIFIED requirement "Edit refuses what is not a regular file of bounded size" (a dangling link is refused; scenario "A dangling link is refused").

## Out of scope

- The 5 headings split to `ex-range-tidy` (ex range arithmetic, patterns, and marks; `ExRange#given`; `SubstituteArgs`' blank test, number reader, and letter test; `GlobalArgs`' delimiter rules) and their `docs/compatibility.md` rows; they stay in the backlog, listed by the queue.
- A descriptor-relative create, rename, and delete (openat): recorded, not fixed (Design, decision 4).
- No `tools/rules.sh` edit; no file of the feature lane.
- Assumption: refusing a dangling link at `:e` is the intended outcome of asking once, since `PathInfo` reports it as an existing entry that is not a regular file, as `MakePath` treats it; Vim would open a new buffer and write through the link.
- Assumption: the "two 64 MiB strings" heading is answered by a double that reports a size its text does not hold, the boundary still checked by `PathInfo#refusal` and the double's read limit as the driver's; the driver's own bounded read keeps its tests in `test/drivers_disk_files.rb`.

## Impact

- README.md: the `:e` sentence names a dangling link among the refused paths.
- docs/architecture.md: unchanged, no layer, port, or module rule changes; the budget and the open rules it names stay as written.
- docs/codebase-map.md: the `replacement.rb`, `substitution.rb`, `open_file.rb`, and `memory_files.rb` lines.
- docs/compatibility.md: the `:e` row and the Differences paragraphs of the files and substitute sections.
- docs/actions.md: unchanged, no bound action changes.
- CLAUDE.md: unchanged, no process change.
- Performance: `Replacement.size` walks the replacement once more per match, the same order of work as the build; a run that stays inside the budget allocates the same strings as before. `:e` makes one port call fewer.
