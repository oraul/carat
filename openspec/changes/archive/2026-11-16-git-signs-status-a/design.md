# Design

## Context

See proposal.md, Why. `Ports::ProcessPort` runs language servers: `spawn`, `write`, `stop`, the output framed by `Domain::RpcFramer` onto the message queue, so it cannot hand back a short command's plain output. `Drivers::ProcessRunner#start` already uses the array form `Process.spawn([argv0, argv0], *rest, ...)`, which never runs a shell. The plugin host builds its request families itself (`plugin_host.rb:85`); `EditorAssembly` holds the one process port (`editor_assembly.rb:322`) but passes it only to the language gateway. The status bar paints a plugin segment as given (`status_bar.rb:250`), so the plugin builds its glyphs from icons by name.

## Goals / Non-Goals

Goals: one host request that runs a program and answers its output, safe against a shell, a hanging child, a flood of output, and a planted program; a git plugin that shows the branch and its counts and fails silent.

Non-goals: asynchronous runs (a short git command answers in milliseconds; the language servers keep the threaded path); a general allow-list of programs per plugin; the line signs.

## Decisions

- One-shot capture on the existing port. `ProcessPort#capture(argv) -> String?` joins `spawn`, `write`, and `stop`, since the assembly, the harness, and every test already build one process port; a second port would change every `EditorAssembly.new` caller. Alternative: `Open3.capture2`, which Spinel bundles, but its array form for a single word and its option handling are not proven under Spinel, while `Process.spawn` with `IO.pipe` is.
- The driver reads on the editor thread with `IO.select` against a 2-second deadline from the monotonic clock, keeps at most 64 KiB, and on the deadline sends `KILL` and answers nil; the child is reaped with `Process.detach`, as `stop` does, so a child that closes its output and lingers never blocks. stdin is the null device, so git never waits for input, and stderr is discarded.
- The request lives in `FileRequests`, the family that already reaches outside the editor (the file port), which takes the process port; the plugin host and the assembly pass it on, and `test/adapters_assembly.rb` checks it is the one instance. Its checks run before the port is called: a non-empty list of non-empty words without NUL, the first without `/`, so a plugin can run only a program on `PATH`, never one a cloned project carries. It answers `TextResponse`, whose base answers a failure rather than raising, as `icon` does (spinel-notes, Known miscompilations).
- The plugin runs `git symbolic-ref --short -q HEAD`, empty outside a repository and on a detached head, then, only for a branch, `git rev-list --left-right --count HEAD...@{upstream}`, empty without an upstream. Both read refs and objects only, never the work tree, so no clean filter, fsmonitor hook, or other command a repository's configuration names runs. `git status --porcelain=v2 --branch` would give both at once but refreshes the index and can run those.
- The segment uses `set_segment(text, 40)`, the branch's documented priority, and is set only when its text changes, so the order of the segments holds and a refresh with the same answer costs no redraw.
- Untrusted output: the first line only, control characters (below 32 and 127) dropped, at most 60 characters; counts are one to nine digits or zero.

## Risks / Trade-offs

- A run blocks the editor thread for at most 2 seconds; on a very slow file system git could approach it. Mitigated by refreshing only on activation, open, save, and focus, never per key or on a timer.
- A branch changed outside the editor shows at the next open, save, or focus change.
- `PATH` still decides which `git` runs, as for any program the user starts from the shell.
