# Design

## Context

`MakePath#call` probes the target (`ProbePath`, a `FilePort#stat`), the parent, and the resolved parent (`ResolveInside`, `real_path`), then calls `FilePort#write(target, "")`, which `DiskFiles` implements with `File.write`: `O_WRONLY | O_CREAT | O_TRUNC`, following a final link. `DiskFiles#read_open` opens with `File.open(path, flags)` and checks `file.stat`. At the pinned Spinel, `File#stat` on a handle opened by path builds a stat handle of that path, and every reader of it calls `stat(2)` on the path again; only a handle with no path (`IO.for_fd`) is `fstat(2)`ed. `File.open` also runs `sp_open_fifo_aware`, which, for a FIFO opened read-only while other threads live, waits until a writer writes or hangs up.

## Decisions

- Exclusive create: `DiskFiles#create(path)` is `File.open(path, File::WRONLY | File::CREAT | File::EXCL | File::NOFOLLOW).close`. `O_CREAT | O_EXCL` fails on any existing entry, a dangling link included, and never follows a final link, so the file made is always a new regular file at the path and needs no check after. `MemoryFiles#create` raises for a file, a directory, or a marked link at the path and for a missing parent. `MakePath` keeps its probes for the messages and calls `create`; the probe is the message, the open is the guard.
- Reads judged by fstat: `read_open` opens with `IO.sysopen(path, flags)`, a plain `open(2)` with the caller's flags, wraps the descriptor with `IO.for_fd(fd)`, a handle with no path whose `stat` is an `fstat(2)` of the descriptor, and reads from it. The `O_NONBLOCK` open of a FIFO returns at once, so the kind check refuses it without the runtime's wait.
- One stat: `DiskFiles#stat` asks `File.symlink?` (the link itself) and then one `File.stat`, rescuing its raise as missing or, for a link, a dangling link. A pinned-Spinel stat handle still reads its path once per reader; the note is recorded in `docs/spinel-notes.md`.
- Opened documents only: `published` returns unless `server.versions` holds the URI, the set `sync` opens and `LanguageServer#forget` prunes on didClose, so the kept diagnostics are bounded by the open buffers of the server's type, each at most `DIAGNOSTIC_LIMIT`.
- A failed send is no request: `request` answers 0 when `deliver` crashed the server (its handle is then 0), so every ask that stores the id stores 0 and `waiting?` stops at once instead of polling every `SERVICE_TIMEOUT` until `ANSWER_LIMIT`.
- `Utf8.utf16_length` walks `size_at`, two units for a four-byte character and one for any other character, a malformed byte included, matching the module's decoder and `String#length`.
- `start` and `restart` share `no_server` (the empty slot and its message) and `started(language, server)` (show and the message).

## Risks

- A server publishing workspace diagnostics before a didOpen loses them until the file opens; ruby-lsp publishes per opened document.
- A parent directory swapped for a link after `ResolveInside` still redirects the create; closing it needs `openat` on a held directory descriptor, which Spinel lacks; recorded in the findings file.
