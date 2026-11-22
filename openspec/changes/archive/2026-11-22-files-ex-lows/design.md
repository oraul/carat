# Design

## Context

`Substitution.line` finds each match through `Search.match_at`, which charges a scan before the engine runs, but then calls `Replacement.expand`, which builds the whole replacement, and only then charges `piece.bytesize * OUTPUT_COST`. A replacement of `n` items `&` on a match of `m` bytes builds `n * m` bytes before the charge can stop the command. `OpenFile#call` calls `FilePort#exist?` and then, when it answered true, `ProbePath#call` (`FilePort#stat`) for the refusal: two questions about one path. `DiskFiles#exist?` follows links (`File.exist?`), while `DiskFiles#stat` reports a dangling link as an existing empty link that is not regular. `MakePath` checks the parent with `ResolveInside` (`FilePort#real_path`) and then creates by path (`FilePort#create`, `O_CREAT|O_EXCL|O_NOFOLLOW`), so a parent directory swapped for a link between the two is followed.

## Goals / Non-Goals

Goals: no replacement is built before it is paid for; `:e` asks the port once; no test builds a 64 MiB string; a test per behavior heading that fails before the fix; the openat gap recorded.

Non-goals: the headings split to `ex-range-tidy`; a descriptor-relative file layer.

## Decisions

1. `Replacement.size(text, line, found)` walks the replacement as `expand` does and returns the bytes it would build, recasing aside: a group adds its bytes, `\r`, `\t`, `\b`, and a carriage return one, `\u`, `\l`, `\U`, `\L`, `\e`, `\E` none, and any other item its character's bytes. `Substitution.line` charges `size * OUTPUT_COST` first and breaks out of the loop when the budget stopped, so nothing is built; after the build it charges the excess, or refunds the shortfall, of a recased piece whose bytes differ, keeping "one charge per character built". Alternative rejected: a bound on `expand` itself (a limit argument), which would spread the budget into `Replacement` and still allocate up to the limit.
2. `OpenFile#call` probes once: `info = @probe_path.call(path)`, `exists = info.exists`, the refusal from the same `info`. A path the port cannot stat stays missing (`ProbePath`), so it opens as a new buffer, as a path that is not there; a dangling link, which `stat` reports as an existing link that is not regular, is refused with `"path" is not a file`, consistent with `MakePath`'s "Already exists" for it. `test/use_cases_ex.rb`'s check of a path found by `exist?` whose stat then raised (E484) described the race this removes: its double's stat raising now reads as nothing there, a new file, and a new check covers the race that is left, a path removed between the one stat and the read, still E484 from the read. Alternative rejected: keeping `exist?` and dropping the stat, which would lose the directory, FIFO, and size refusals.
3. `MemoryFiles#pad(path, bytes)` records bytes that `stat` adds to the text's size and `read` adds to it for the limit check, so a test can put a file of 64 MiB without building it; `MemoryFiles#dangling(path)` marks a link with no target, which `stat` reports as `DiskFiles#stat` does and `exist?` and `read` treat as absent. `test/editor_cmdline.rb` pads `big.bin` to one byte over the limit and `edge.bin` to exactly the limit; the edge check reads the two-byte text it holds.
4. The openat gap is recorded, not fixed. Closing it needs the create, the rename, and the delete made relative to a directory descriptor opened and checked once (`openat`, `mkdirat`, `renameat`, `unlinkat` with `O_NOFOLLOW` and `O_DIRECTORY`), or the process's working directory moved into the parent for the call and back by descriptor (`fchdir`). Neither the pinned Spinel nor Ruby's core offers them, and moving the working directory by path would change what every relative path of the editor names while it is away. The finding names the three headings, the locations, and that outline.

## Risks / Trade-offs

- A user who opened a dangling link to create its target now gets a refusal; they can open the target path itself.
- `Replacement.size` must follow `expand`'s items; `test/domain_substitute.rb` compares the two over every item kind, so a new item added to one and not the other fails there.
