# Backlog: carat/drivers/process_runner.rb

## The language server outbox has no bound

- Where: the per-child outbox queue in `carat/drivers/process_runner.rb` (line 58 at eb63fb4). Periodic security Low (5).
- Why it matters: a server that stops reading its input makes every `didOpen` and `didChange` body accumulate in editor memory.
- Fix outline: count the queued bytes per handle and treat the server as crashed past a cap, with a driver test over a child that never reads. Queued in `lsp-client-tidy`.
- Category: security
- Added: 2026-11-07

## The process runner's reader queues bodies without a bound

- Where: the reader thread in `carat/drivers/process_runner.rb` (line 106 at fb09c6b). Periodic security Low (4) at fb09c6b.
- Why it matters: it queues every framed body of up to `BODY_LIMIT` with no bound while the gateway drains 64 per idle tick, so a flooding language server can exhaust the editor's memory.
- Fix outline: cap the queued bodies or bytes per handle and stop the server with an overflow message past the cap, with a driver row. Queued in `lsp-client-tidy`.
- Category: security
- Added: 2026-11-07

### ProcessRunner#capture override lacks its return in prose
- Location: carat/drivers/process_runner.rb:76
- Why: capture overrides the port with only a `# @rbs argv:` line and no return in prose, against the inline RBS rule for overrides.
- Fix: add a comment stating it answers the output or nil.
- Category: editor
- Added: 2026-11-16

### capture now times out on exactly 64 KiB with stdout held open
- Location: carat/drivers/process_runner.rb:110
- Why: the loop waits for a byte past CAPTURE_LIMIT or the end, so a program printing exactly 65,536 bytes and holding stdout open (a background child) now times out to nil where it answered before.
- Fix: keep the < loop and trim an incomplete trailing sequence of the kept 64 KiB with the Domain::Utf8 character-size logic instead of reading past the limit.
- Category: editor
- Added: 2026-11-16

### ProcessRunner class comment describes the old capture loop
- Location: carat/drivers/process_runner.rb:15
- Why: the class comment still says capture reads until CAPTURE_LIMIT bytes are kept, while collect now reads past the limit and cuts before a character.
- Fix: reword the class comment to match collect's.
- Category: editor
- Added: 2026-11-16

### cut_point carries a guard that cannot fail and belongs in Domain::Utf8
- Location: carat/drivers/process_runner.rb:131
- Why: the at > 0 guard can never fail (at starts at CAPTURE_LIMIT and drops at most 3), and a backward UTF-8 boundary belongs beside Domain::Utf8.boundary.
- Fix: drop the guard and move cut_point to Domain::Utf8 as the backward counterpart of boundary.
- Category: editor
- Added: 2026-11-16

### Relative PATH entries let git_signs run a project's ./git

- Location: carat/drivers/process_runner.rb:98, carat/use_cases/plugins/file_requests.rb:139 (sprint-9 review, security Low (5)); queued in `process-capture-hardening`.
- Why it matters: run_program looks the program up on the PATH and the no-slash check does not stop a relative or empty PATH entry (".", "::", a trailing ":"); git_signs is on by default and runs git when it activates, so opening carat in a checkout shipping an executable ./git runs it with no user action.
- Fix outline: resolve argv[0] against only the absolute PATH directories, spawn the absolute path found, refuse when none is found; a driver test with PATH=".:..." and a planted program in the working directory.
- Also: carat/use_cases/plugins/file_requests.rb
- Category: security
- Added: 2026-11-16

### capture leaves a child past the output limit running

- Location: carat/drivers/process_runner.rb:87 (sprint-9 review, quality); queued in `process-capture-hardening`.
- Why it matters: capture kills the child only on timeout; when the output passes CAPTURE_LIMIT it closes the pipe and detaches, so a child ignoring SIGPIPE runs on with no deadline.
- Fix outline: kill the child unless collect read the output to its end; a case with a SIGPIPE-ignoring child.
- Category: editor
- Added: 2026-11-16

### The language server stop signals TERM before the writer sends the queued shutdown
- Location: carat/drivers/process_runner.rb:81
- Why: `stop` sends TERM on the editor thread before the writer thread has written the shutdown and exit requests the gateway queues, so the graceful language server shutdown is usually skipped and the server ends without flushing its state.
- Fix: have the writer drain signal and detach after it closes the child's input (the pid still unreaped), keeping the immediate TERM only where nothing may wait, or say in the `ProcessPort` comment that shutdown is best effort.
- Category: editor
- Added: 2026-11-17

### ProcessRunner repeats its spawn and signal bodies (sprint-16 sweep quality)

- Location: carat/drivers/process_runner.rb:124 and :189 (start_quiet, start), :166 and :175 (kill, terminate).
- Why: the same Process.spawn with different streams, and two signal bodies differing in the signal and guard.
- Fix outline: one spawn helper taking the environment and streams, one signal(name, pid) with the guard. Pool item `lsp-tidy`.
- Category: editor
- Added: 2026-11-18

### Misleading contract (sprint-20 sweep quality, process_runner.rb:71)

- Location: `carat/drivers/process_runner.rb:71`
- Why: misleading contract: write answers true after the writer thread has already stopped on a broken pipe (drain breaks silently at 243), so the gateway's crash-on-failed-write in deliver (json_rpc_language_gateway.rb:1482) fires only for a stopped handle and the outbox keeps growing until the reader's exit message arrives
- Fix: have drain mark the handle closed when write_bytes fails (or document that a broken input is reported only through the exit message and drop the gateway comment)
- Category: editor
- Added: 2026-11-19

### The process runner's stop can signal a reused pid
- Location: carat/drivers/process_runner.rb:97 (security Low, confidence 2)
- Why: stop sends KILL to a bare pid after checking waiter.alive?; if the child is reaped and its pid reused by another process between that check and the signal, the KILL could hit an unrelated process owned by the same user, a window the comment acknowledges and which is practically very narrow.
- Fix: have the detach waiter itself send the KILL, or use a pidfd where Spinel supports it, so the signal can only reach a child that has not been reaped yet.
- Category: security
- Added: 2026-11-20

### carat/drivers/process_runner.rb:133: start_quiet repeats start (line 198): the same Process.spawn and (sprint-22 sweep quality)

- Location: `carat/drivers/process_runner.rb:133`
- Why: start_quiet repeats start (line 198): the same Process.spawn and rescue, with a different in: and an environment; and the header comment at lines 20-22 is wrapped unevenly
- Fix: one start(argv, environment, input, output), with capture passing File::NULL and a server passing {}, and rewrap the comment
- Also reported: sprint-22 sweep note 61 (the class comment wrap, process_runner.rb:17)
- Category: editor
- Added: 2026-11-20

### carat/drivers/process_runner.rb:217: names Domain::RpcFramer and Domain::ServiceMessage (line 225) without requiring them (sprint-22 sweep quality)

- Location: `carat/drivers/process_runner.rb:217`
- Why: names Domain::RpcFramer and Domain::ServiceMessage (line 225) without requiring them; it requires only ../ports/process_port, which requires nothing, so it compiles only after carat.rb loaded them
- Fix: add require_relative ../domain/rpc_framer and ../domain/service_message
- Also: carat.rb
- Category: editor
- Added: 2026-11-20

### capture starts a waiter thread per program at carat/drivers/process_runner.rb:121 (sprint-28 sweep quality, note 41)

- Location: carat/drivers/process_runner.rb:121
- Why: Process.detach starts a thread each git_signs refresh, while area 17 and CLAUDE.md Stack name the server reader and writer threads as the only ones.
- Fix: reap with Process.wait once output ended or after the kill, or say so in the docs.
- Also: CLAUDE.md
- Category: editor
- Added: 2026-11-22

### start_quiet and start (line 219) repeat the same program_path at carat/drivers/process_runner.rb:136 (sprint-30 sweep quality, note 38)

- Location: carat/drivers/process_runner.rb:136
- Why: start_quiet and start (line 219) repeat the same program_path lookup, empty check, Process.spawn of [program, program], and SystemCallError rescue, differing only in the environment and the in: stream
- Fix: one private spawn_program(environment, argv, input, output) both call
- Category: editor
- Added: 2026-11-23
- Merged: ### start_quiet and start (219) repeat the program_path lookup, the at carat/drivers/process_runner.rb:136 (sprint-30 sweep quality, note 74)
- Location: carat/drivers/process_runner.rb:136
- Why: start_quiet and start (219) repeat the program_path lookup, the empty check, the spawn, and the rescue, differing only in environment and streams
- Fix: one private spawn helper taking the environment and the in/out streams

### the class comment and the map's area 17 entry at carat/drivers/process_runner.rb:10 (sprint-30 sweep quality, note 39)

- Location: carat/drivers/process_runner.rb:10
- Why: the class comment and the map's area 17 entry say the reader and writer threads per child are the only threads Carat starts, but stop (line 99) and capture (line 121) each start a waiter thread through Process.detach, a capture per git command
- Fix: say the reader, the writer, and the detach waiters are the only threads, in the comment, the map, and CLAUDE.md Stack if it is meant to hold
- Also: CLAUDE.md
- Category: editor
- Added: 2026-11-23

### program_path uses a name holding a slash as given at carat/drivers/process_runner.rb:151 (sprint-30 sweep quality, note 44)

- Location: carat/drivers/process_runner.rb:151
- Why: security, unexamined: program_path uses a name holding a slash as given, so a relative configured program such as bin/ruby-lsp resolves against the project's working directory; for the security reviewer
- Fix: judge the point named in Why against the code; fix it with a test or record why it holds
- Category: editor
- Added: 2026-11-23
- Merged: ### a program name with a slash is used as at carat/drivers/process_runner.rb:151 (sprint-30 sweep quality, note 82)
- Location: carat/drivers/process_runner.rb:151
- Why: possible security point, unexamined: a program name with a slash is used as given, so a relative one resolves against the project's working directory
- Fix: for the security reviewer to judge

### the class comment has one overlong line and broken at carat/drivers/process_runner.rb:23 (sprint-30 sweep quality, note 75)

- Location: carat/drivers/process_runner.rb:23
- Why: the class comment has one overlong line and broken wrapping (A handler, unlike IGNORE, resets to the default in), and line 8 still says it starts language servers though capture runs git and other programs
- Fix: rewrap and say child processes
- Category: editor
- Added: 2026-11-23

