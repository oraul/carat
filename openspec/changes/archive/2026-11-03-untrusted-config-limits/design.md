# Design

## Context

See proposal.md for why. The facts that shape the approach, checked on the pinned Spinel with a probe compiled outside the repository:

- A regular expression on a string that is not valid UTF-8 raises `ArgumentError`; `getbyte`, `byteslice`, `chars`, and `ord` do not.
- `File.open(path, File::RDONLY | File::NONBLOCK)` opens a FIFO without waiting for a writer; `File#stat` on the opened file answers `file?` and `ftype`; `File#read(n)` reads at most n bytes and answers an `ASCII-8BIT` string, which `force_encoding(Encoding::UTF_8)` relabels; `File.file?`, `File.realpath`, `File.symlink`, `File.mkfifo`, and `Dir.chdir` work.
- `FilePort#read(path)` has two callers, `OpenFile` and `RcConfigGateway`; `PathInfo` is built in the driver, the double, and `PathInfo.missing` only.
- `RcParser.key?` already checks, on bytes, exactly the shape `Keymap::ACTION_NAME` matches: two or more segments of lowercase letters, digits, and underscores joined by dots.

## Goals / Non-Goals

**Goals:**

- No byte in any configuration file, manifest line, or opened file can raise outside a rescue, hang the editor, or make it allocate without bound.
- Every refusal says what was refused in the words the user already knows: `file:line: message` for a line, `source: reason` for a whole configuration file, Vim's messages for `:e`.

**Non-Goals:**

- Closing every check-then-use race on the disk. The open that follows the check is itself safe (non-blocking, regular-file check on the opened descriptor, bounded read), so a race can at worst swap one regular file of bounded size for another.

## Decisions

### The parser refuses illegal bytes, and the action check reads bytes

`RcParser.parse_range` first walks the line with `Utf8.size_at` and fails with `illegal byte` when a byte of 128 or more starts no well-formed sequence. Every configuration line, from any file, and every manifest line (bindings, options, the scratch keymap of a plugin window) goes through it, so the check sits once at the boundary rather than in each scope's reader. `Keymap.action_name?` becomes `RcParser.key?(value, 0, value.bytesize)` and `ACTION_NAME` goes, so the check also holds where a value did not come through the parser (a binding added by `Keymap#bind`, the run-time dispatch in `HandleKey`). Alternative: rescue `ArgumentError` around the regular expression. Rejected: it hides the byte instead of reporting the line, and a rescue on the key path costs more than a byte loop.

### A whole-file refusal is a problem of the file, not of a line

`Config#unreadable(source)` becomes `Config#refuse(source, reason)`, which takes the next file ordinal and notes `"#{source}: #{reason}"`, so a refused file sorts in load order among the line problems. The gateway refuses, in order: a project file that is a link (`is a symbolic link, not read`), a file that `stat` says is not regular (`is not a regular file, not read`), one larger than `LIMIT` (`is larger than 1048576 bytes, not read`), and a read that raises (`cannot be read`, as before). A directory stays a silent skip, as the existing spec says. The user file may be a link, since dotfile managers link it, but it gets the same type and size checks.

### The port reads only a regular file, at most a limit

`FilePort#read(path, limit)` replaces `read(path)`: it answers the text of a regular file of at most `limit` bytes and raises `IOError` with `Not a regular file`, `Is a directory`, or `File too large` otherwise. `DiskFiles` opens with `RDONLY | NONBLOCK`, checks `stat.file?` on the opened file, reads `limit + 1` bytes to tell a file that is exactly the limit from a larger one, closes in an `ensure`, and relabels the bytes UTF-8, as `File.read` gave them. `PathInfo` gains `regular` (following a link, as `directory` does), so callers can refuse before opening with their own message. `MemoryFiles` marks a path special (`special(path)`, a FIFO or a device) and records a link's target (`link_to(path, target)`).

### OpenFile checks the kind and the size before it reads

After `exist?`, `OpenFile` asks `stat` through `ProbePath`, the one the assembly builds and the plugin host shares, so a path it cannot stat (removed after `exist?`) is `E484: Can't open file path`; it answers Vim's `"path" is a directory` and `"path" is not a file`, and `E484: Can't open file path: File too large` above `LIMIT` (64 MiB), all as failures, so the window keeps its buffer. The read then passes the same limit, and any error it raises is still E484.

### MakePath compares real paths

After the lexical checks (which keep their messages and order), `MakePath` asks the port for the real path of the root and of the parent and refuses with `Outside the tree root` unless the parent's real path is the root's or lies inside it. The parent exists at that point (it passed the directory check), so `real_path` answers; any error is the same refusal. The target itself needs no resolution: when it is a link, even a dangling one, `stat` says it exists and the request is refused as `Already exists`. The plugin-explorer design chose lexical containment so a linked directory shown expanded inside the tree stays usable; resolving both sides keeps that for links that stay inside the root and refuses only those that leave it. `FilePort#real_path(path)` is new: `File.realpath` in the driver, a walk over the link targets in the double.

### tabstop and shiftwidth are checked in Options.apply

`apply` reads the number into a local and refuses `tabstop` outside 1 to 9999 and `shiftwidth` outside 0 to 9999 with `option.NAME takes a number from LOW to 9999`, keeping the earlier value. Vim refuses a tabstop of 0 and above 9999; a shiftwidth of 0 means the tabstop.

## Risks / Trade-offs

- [A Latin-1 comment in a hand-written `.caratrc` is now a reported line] -> the report names the file and line, the line was a comment, and the rest loads; this matches how a control character in a comment is treated.
- [A file above 64 MiB no longer opens] -> the editor's line array would hold it, slowly, before; the message says why, and the limit is one constant.
- [The real-path check adds two `realpath` calls per create] -> a create is a user action, not a key path.
- [A check-then-open race on the project directory] -> the open is non-blocking and bounded, so the worst outcome is reading another regular file of at most the limit; recorded under Non-Goals.
