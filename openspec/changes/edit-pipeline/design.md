# Design

## Context

See proposal.md for the motivation. `Buffer` is a `Struct` record whose `lines` member is an `Array[String]`. Its four primitives all end in `set_lines`, which does `lines[from...to] = new_lines`, sets `modified`, and increments `changes`. Two use cases bypass the primitives with `buffer.lines = fresh` (the `:e!` reload in `OpenFile` and `replace_lines` in `PluginHost`), and three places write `modified` by hand (`SaveFile`, the reload, and the plugin host's scratch refresh and deleted-file rule). Edits arrive from `Domain::Operators`, `Operate`, `InsertText`, `EnterInsert` (`o` and `O`), `LeaveInsert` (the block repeat), `OperateOnSelection`, and `PluginHost#edit_buffer`; every one of them already calls a primitive, so the use cases need no change apart from the transaction boundaries.

Every key goes through `HandleKey`. A completed normal or visual command, an insert-mode action such as `insert.newline`, and a command-line action such as `cmdline.execute` all reach `Dispatcher#call`; typed insert text goes from `HandleKey#insert_literal` straight to `InsertText#call`, and Escape in insert mode is the `mode.normal` action, which the dispatcher routes to `LeaveInsert`.

Spinel constraints that shape the code: an `Array[T]` pin applies only to a builtin `T`, so an array of records is `Array[untyped]` read through a method whose return type is declared, as `Layout#node` does; `# @rbs @member` pins apply to a `Data` subclass only when its body holds at least one statement; empty array literals take the pinned type only when stored through a writer after `super()`; a method called with two different argument types widens for the whole program.

Measured on Spinel at 2b8b2ba, with the line array of 100,000 lines and the edit in the middle (the scratch micro benchmark built from the pinned compiler):

| Lines added then removed | `insert` and `delete_at` per line | one in-place pass | slice assignment |
| --- | --- | --- | --- |
| 1 | 29 us | 239 us | 1549 us |
| 8 | 260 us | 326 us | 1739 us |
| 16 | 513 us | 253 us | 1615 us |
| 64 | 2064 us | 249 us | 1667 us |

At 1,000,000 lines the crossover between the first two columns lies between 4 and 8 lines. A splat `insert(at, *lines)` and `slice!(at, n)` scale with the span too (47 us for one line, 1187 us for 64), so they are no better.

## Goals / Non-Goals

**Goals:**

- One internal splice that every primitive ends in, and nothing outside `Buffer` that changes the line array.
- No allocation in proportion to the buffer per edit; `ddP` and `o<Esc>dd` under 30 us of key handling per key on 100,000 lines.
- A change record per primitive and a transaction per command, insert session, or plugin edit request, kept where the undo change can take them.

**Non-Goals:**

- Undo itself, the undo tree, and the dot command.
- Changing the storage from an array of lines.
- Moving signs, marks, or highlight states with inserted and deleted lines.

## Decisions

### The line array stays a member, guarded by a lint rule

The member keeps the name `lines`, so every reader (`buffer.lines` in tests, the presenter, the plugin host's copy) is unchanged. Spinel's `Struct` writers are public and `private :lines=` is not something the codebase relies on anywhere, so a `test/lint.rb` rule enforces the boundary instead: outside `carat/domain/buffer.rb`, no file under `carat/`, `bin/`, or `test/` may assign `.lines =`, assign an element through `.lines[...] =`, or call a mutating method (`<<`, `insert`, `delete_at`, `push`, `pop`, `shift`, `unshift`, `concat`, `clear`, `replace`, `slice!`, `delete`, `fill`, and the bang methods) on `.lines`. Renaming the member and exposing a read-only `lines` method was the alternative; it would still leave a public writer under the new name, so it needs the same lint rule and gains nothing.

### One splice, in place

`Buffer#splice(from, to, new_lines)` is private. It clamps the rows into the buffer, turns an edit that would leave no line into one that inserts `[""]`, takes the removed lines as a slice (proportional to the span only), applies `LineSplice.apply`, counts the change, and hands a `ChangeRecord` to the open transaction. `insert`, `delete`, `replace`, `set_lines`, and `reload` each compute the new lines of the rows they touch and call `splice` once, so `replace` is now one change.

`Domain::LineSplice.apply(lines, from, to, new_lines)` overwrites the rows both sides have in common, then grows or shrinks by the difference: one `insert` or `delete_at` per line when the difference is at most `LineSplice::SMALL` (8, from the table above), otherwise one pass that moves the tail by the difference and pushes or pops the extra slots. Both paths are proportional to the tail and allocate nothing beyond the array's own growth. The helper is a module function over `Array[String]`; a later per-line array of another element type (highlight states, marks) gets a sibling function with the same shape, because Spinel types a method's parameters once for the whole program. Signs are a hash keyed by the row as text, not a per-row array, so they are not spliced; their not following inserted lines is recorded in the backlog.

### Records and transactions

`ChangeRecord < Data.define(:buffer_id, :row, :removed, :inserted)` is immutable; `removed` and `inserted` share the line strings with the buffer, which is sound because no code mutates a line in place (every primitive builds new strings; a test asserts identity and that a record is unchanged by later edits). It has `delta` so its pins apply.

`Transaction < Struct.new(:buffer_id, :before, :after, :records)` holds the cursor positions and the records as `Array[untyped]`, stored through the writer after `super()` and read through `record_at(i)`, which declares the `ChangeRecord` return.

`Buffer` gets `begin_transaction(position) -> bool`, which opens a transaction and returns true, or returns false when one is already open (the caller then joins it and must not close it), `commit_transaction(position)`, which closes the open one, and `transaction_open?`. Closing a transaction with records sets `last_transaction` and increments `closed_count`; an empty one is discarded. A primitive called with no transaction open wraps its single record in a transaction of its own, with the record's first row as the cursor before and after. `last_transaction` and `closed_count` are the sink the undo change replaces with the undo tree.

The three boundaries:

- `Dispatcher#call` opens on the current buffer with the cursor position before running any action, and closes afterwards unless the editor is now in insert mode on that same buffer, in which case the transaction continues as the insert session. If the editor is not in insert mode and the buffer still has a transaction open (an insert session left without `LeaveInsert`, for instance because a plugin moved focus), the dispatcher closes it first so it cannot swallow later commands.
- `LeaveInsert#call` closes the current buffer's transaction after the block repeat and the cursor move, ending the insert session that `i`, `a`, `o`, `c`, a visual `c`, `I`, or `A` began. Typed text, `insert.newline`, and the other insert actions join it.
- `PluginHost#edit_buffer` and the scratch refresh (`set_scratch_lines`, and `open_scratch` on a shown buffer) open on the target buffer and close when they opened. Inside a command bound to a plugin action they join the command's transaction.

The alternative of passing a transaction object through every use case and primitive would change the signature of every operator and use case; keeping the open transaction on the buffer keeps the primitives' signatures, as the architecture asks.

### The modified flag is derived

`modified` becomes a method: `changes != saved_change`. `saved_change` replaces the `modified` member in the same position, set to the counter by `mark_saved` (called by `SaveFile` and by `reload`) and to -1 by `mark_unsaved` (the plugin host's deleted-file rule), a number the counter never reaches. A fresh buffer has both at 0. The writer `modified=` is gone; tests that set the flag call `mark_saved` or `mark_unsaved`.

### Buffer ids

`EditorState` gets `next_buffer_id`, starting at 1. `add_buffer` and the constructor give a buffer with id 0 the next id when it enters the list. Every path that shows a buffer in a window lists it first (`load`, `add_buffer` in `open_tab` and `place_side`), so every buffer the user can edit has an id. A buffer built in a test and never listed has id 0, and its records carry 0.

## Risks / Trade-offs

- [A use case later mutates a line string in place and silently changes a record] → Lines are built with `+`, slices, and `dup` today; the domain test asserts a record's strings are unchanged by later edits, and the coding convention in `CLAUDE.md` states the rule.
- [A transaction left open forever groups unrelated edits] → The dispatcher closes a stale one when it runs outside insert mode, and `LeaveInsert` closes on every exit path.
- [Every key now allocates a transaction and two positions even when nothing changes] → A few small objects per key, measured within the noise of key handling; edits no longer allocate a copy of the buffer, which dominated before.
- [`:e!` and the scratch refresh now fire `buffer_change`] → Intended: the text did change. No shipped plugin subscribes to `buffer_change`; the plugin-host spec gains a scenario for it.
- [The lint rule's textual match misses an aliasing write such as `l = buffer.lines; l << x`] → Accepted; the rule catches the direct forms, review catches the rest, and the undo change will rely on records rather than on the array.

## Migration Plan

None: no data, configuration, or plugin API change. Rolling back is reverting the squash commit.
