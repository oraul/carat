fix(drivers): create without following links and bound lsp diagnostics

## Summary

Creating a file through MakePath no longer writes through a symbolic link planted at the target after the existence probe, file reads judge the kind of what they opened on the descriptor and refuse a FIFO at once, and the language server client keeps published diagnostics only for documents it opened. These close two security Lows from the sprint-14 sweep and two periodic reviews (a create in an untrusted project could truncate a file outside the tree, and a hostile server could grow the kept diagnostics without bound) together with eight tidies in the drivers and the language gateway.

---

## Changes

- Add FilePort#create, an exclusive no-follow create of an empty regular file that refuses anything already at the path, a link included, and make MakePath create files through it, with the memory double matching it
- Change DiskFiles#read and #read_no_link to open with IO.sysopen and judge the kind on the opened descriptor, so a path swapped after the open is not judged again and a FIFO is refused without waiting for a writer
- Change DiskFiles#stat to read one File.stat after the link check instead of four separate file calls
- Fix the language gateway to drop a publishDiagnostics for any URI the server was not told is open
- Fix the gateway's request to answer 0 when the write crashed the server, so a failed completion, hover, definition, signature, or symbol send leaves nothing in flight and the input stops polling
- Refactor the gateway: start and restart share their tail, apply(set) becomes draw_published(icons) without the branch Buffer#set_diagnostics already makes, listed becomes private, and the UTF-16 length moves to Domain::Utf8.utf16_length, counting each malformed byte as one unit
- Change ProcessRunner to require the framer, service message, and queue port it names instead of relying on the require order of carat.rb
- Add tests for the exclusive create, the descriptor-judged reads, the published-diagnostics bound, the failed completion and hover sends, the UTF-16 length, and the NO_COLOR read of AnsiTerminal
- Document the FilePort create in the FilePort row of the architecture, the create and the descriptor-judged read in the code map, the two Spinel facts behind them in the Spinel notes, and the four added scenarios in the config-files, language-server, and plugin-host specs

---

## Testing

- Run the security review of the committed diff, passed with no High or Medium finding and one Low recorded as a finding
- Run the check stages docs-lint, dev-build, test-build, test-run, diagnose, bench-budget, tools-test, gates, and metrics at the reviewed head, all pass
- Run the benchmark comparison against main's recorded figures, passed with no regression
- Run make spec-validate after the archive, all 56 items pass

---

## Notes

A parent directory swapped for a link between ResolveInside and the create is still followed, since Spinel offers no openat; it predates this change and is recorded as a finding with an outline that needs a file identity check before any interim delete. A server that publishes diagnostics for a file not yet opened has them dropped until the file is opened, as ruby-lsp publishes only for documents it was told about. A malformed byte in a position's line now counts one UTF-16 unit where it counted 0 or 2 before.
