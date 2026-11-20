### DiskFiles#stat makes four system stats per path
- Location: carat/drivers/disk_files.rb:53 (`stat`), called by list_tree.rb, probe_path.rb, rc_config_gateway.rb, and editor_assembly.rb
- Why: a non-link path pays `File.symlink?`, `File.exist?`, then `File.size`, `File.mtime`, `File.directory?`, and `File.stat(path).file?`, each its own system call, on every tree listing and probe; split from lsp-tidy by the plan and queued as `lsp-tidy-c`
- Fix: take one `File.lstat` and, for a link, one `File.stat`, and read the size, mtime, directory, and regular flags from those; a test over test/drivers_disk_files.rb's directory keeps the flags of every row

### NO_COLOR leaves syntax, bars, and messages colored
- Location: carat/adapters/editor_assembly.rb:591 and :593 (the only readers of `no_color?`), carat/adapters/frame_presenter.rb:353 (`plain=`)
- Why: under NO_COLOR only the border, the status bar's glyphs, the start art, and the hover float go plain, while the syntax highlight, the bars' colors, and the message row keep their colors; split from lsp-tidy by the plan and queued as `lsp-tidy-c`
- Fix: have the frame presenter drop every color attribute when plain (keeping bold, reverse, and underline), with a frame test per surface under NO_COLOR that fails before the fix

### No test reads NO_COLOR through AnsiTerminal
- Location: carat/drivers/ansi_terminal.rb:24 (`@no_color` read once from the environment), :30 (`no_color?`); only bin/carat.rb:27 constructs it
- Why: every NO_COLOR test goes through FakeTerminal's writer, so a regression in the driver's own read of the variable (set, empty, unset) passes every test; split from lsp-tidy by the plan and queued as `lsp-tidy-c`
- Fix: a driver test constructing AnsiTerminal over pipes with NO_COLOR set, set empty, and unset, checking `no_color?` for each

### The language server client repeats itself and names little of what it uses
- Location: carat/adapters/json_rpc_language_gateway.rb `start` and `restart` (the same "No language server for this buffer" and "Cannot start" blocks), `stop` and `restart` (the per-server forget loops), `request` and `notify` (each builds the envelope)
- Why: the duplicated blocks drift apart on the next edit, and the client's long header comment carries what named helpers would; split from lsp-tidy by the plan and queued as `lsp-tidy-c`
- Fix: one private `launch_shown(language)` for the shared start tail, one `forget_all` loop, and `notify` built on one `envelope(name, params)` that `request` adds the id to; the gateway's tests pass unchanged

### Requests for a buffer outside the working directory are sent though it was never opened
- Location: carat/adapters/json_rpc_language_gateway.rb `complete`, `send_hover`, `send_definition`, `send_signature`, and `send_symbols` (each checks only that the buffer has a path)
- Why: since lsp-tidy a buffer outside the working directory is never opened on the server, yet a completion, hover, definition, signature, or symbol request still names its URI; the server answers for a document it was never sent, usually with an error or nothing, and it learns the path
- Fix: have `running_server` or the request senders skip a buffer the server has no version for (`server.versions[uri]` nil), with a test that K and gd in an outside file send no request

### A concurrent lane's bench fails another lane's check as an escape
- Location: tools/run_state.sh, escape_mark, main_scan and bench_compare (metrics_out, last.tsv)
- Why: the check of one lane failed with "a stage wrote outside its clone" naming the main checkout's build/metrics/current.tsv and last.tsv, written at 07:39:14 and 07:39:22 by the other lane's bench phase, which runs in the main checkout right after its own metrics stage; every stage of the failed check exited 0, so a clean change costs a full check round whenever two lanes overlap.
- Fix: have bench write its figures under the lane's own build/ (or build/stages/CHANGE/), or leave build/metrics out of main_scan like build/pipeline and build/stages, with a tools_test case running a bench beside a check.
