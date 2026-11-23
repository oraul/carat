# Design

## The place and the format

The state file is `.local/state/carat/recent_files` under `FilePort#home`: outside every project, so a cloned repository cannot plant it, and in the XDG state place, since the list is state, not configuration. No environment lookup is made (the port has none, and the user's configuration path is likewise fixed). With no home directory nothing is read or written.

One absolute path per line, most recent first, each ending in a line feed, UTF-8. A line is usable when it is absolute, longer than the root, at most 4096 bytes, valid UTF-8, and free of C0 controls, DEL, and the C1 controls. The same rule applies on write (a file named with a newline is never written, which would split it) and on read (a planted or damaged file yields fewer paths, never a line a terminal could act on). A carriage return ending a line is dropped. A read takes at most 1 MiB and never waits (`FilePort#read` refuses a FIFO or a device); every failure reads as no paths.

## Absolute paths and the working directory

The buffers keep the path they were opened with (the status bar shows it), so the list resolves it when a file is shown: `BufferList#base` is the working directory of the last open, set by `OpenFile` at every call from `FilePort#cwd`, since the domain has no port. The editor has no `:cd`; the file double's `move_to` stands in for it, which is why `base` is refreshed at each open and not once.

The list is shown through the working directory of the moment: `BufferRequests#recent_files` maps each path with `PathPolicy.shown`, relative below it and absolute elsewhere. The finder, which opens a row by its text, then opens the file the row names after a `:cd`, and its rows read as before inside the project. `Host#recent_files` keeps its signature.

## Load and save

`EditorAssembly#open` runs its private `restore_recent_files` first, so the file opened at start goes above the restored ones; `restore_recent` appends the rest up to the bound. `EditorAssembly#close` runs its private `save_recent_files`; `bin/carat.rb` calls it in the `ensure` that already covers every exit (`:q`, a signal, an error), after the screen is restored. A save with no usable path writes nothing, so a session that opened no file keeps the earlier list. Both are private methods of the assembly, not use cases: a new use case class made the whole-program diagnose report an unresolved call in the enumerable builtins, a Spinel analysis quirk, and the two are small. Both swallow `StandardError`: the list is a convenience and must never stop the editor starting or ending.

The write is a plain `FilePort#write` after making each missing directory with `exist?` and `mkdir` (the port has no recursive make). It may follow a link in the user's own home, as the configuration file does.

## Known limit

A buffer opened before a working directory change and shown again after a later open resolves its relative path against the newer base. With no `:cd` in the editor the directory never changes in production; a buffer carrying its absolute path would end it and is recorded in the findings.
