# Backlog: bench/keys.rb

## Opening 100,000 plain lines is slower than opening them highlighted

- Where: the `open-plain` and `open-ruby` scenarios of `bench/keys.rb`, which open the same generated 100,000-line Ruby source without and with the ruby plugin.
- Why it matters: in the `syntax-highlighting` measurements the plain open took a median of about 119 ms over eight runs and the highlighted one about 19 ms, while 10,000 lines open in about 2.5 ms either way; the plain time grows faster than the line count, which points at a collection or a growth step during the open that the plugin's startup allocations happen to move out of it, so the open time of large files depends on where the collector runs.
- Fix outline: report the collections and their time during the open in the benchmark (`GC.stat("cycle")` and `GC.total_time` around `assembly.open`), find the allocation that triggers them while splitting the file into lines, and size or reuse that storage so the open stays linear.
- Category: code-quality
- Added: 2026-11-03

## The benchmark's plugins column holds an option toggle

- Where: `bench/keys.rb:255` (`noguides` in the plugins column). Periodic quality at ce6abdb; queue item: the backlog batches.
- Why it matters: the plugins column mixes an option toggle with plugin sets, so a reader of the results misreads it.
- Fix outline: a setup or options column.
- Category: code-quality
- Added: 2026-11-10

### bench NullTerminal breaks the double naming rule

- Location: bench/keys.rb:30 (sweep, quality).
- Why: a double not starting with Fake, Memory, Manual, or Fixed.
- Fix outline: rename it FakeCountingTerminal.
- Category: code-quality
- Added: 2026-11-17
