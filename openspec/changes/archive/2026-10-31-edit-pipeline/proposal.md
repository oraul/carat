# Proposal

## Why

Undo and redo, syntax highlighting, plugin events, and language services all need one place every buffer edit passes through, a record of what each edit changed, and edits that do not copy the whole buffer. Today two reloads assign the line array directly and are not counted as changes, `replace` counts as two changes, the modified flag is written by hand in two use cases, and every edit that changes the line count goes through a slice assignment that copies the tail of the buffer: on 100,000 lines `ddP` costs about 355 microseconds per key and `o<Esc>dd` about 253, almost all of it in the splice, with a large allocation per edit.

## What Changes

This change is outside the roadmap order of `docs/architecture.md`: it is the first item of the core-quality queue the user approved before more plugins, and it lays the ground for roadmap item 4, `undo-and-registers`, which consumes the transactions it adds, and for items 8 and 10, which will read the change records. It delivers the edit path that section 4 of the architecture already describes for `Buffer` and `Transaction`.

- Route every buffer edit through one internal splice in `Buffer`: `insert`, `delete`, `replace`, `set_lines`, and a new `reload(lines)` primitive that replaces the whole text and leaves the buffer unmodified. `replace` becomes one change instead of two. The `:e!` reload and the plugin host's scratch refresh use `reload`, so both now count as a change, which plugins observe as `buffer_change` when the reloaded buffer is current.
- Make the line array writable only inside `Buffer`: a new `lint` rule refuses an assignment to `lines`, or a mutating call on it, anywhere outside `carat/domain/buffer.rb`, tests included.
- Add a splice helper that changes a line array in place: an overwrite when the line count stays, `insert` and `delete_at` for spans of up to eight added or removed lines, and one in-place pass for larger spans, so no edit allocates in proportion to the buffer.
- Add an immutable change record per primitive call (the buffer's id, the first row, the lines removed, and the lines inserted, sharing the line strings with the buffer) and a transaction that groups the records of one command with the cursor before and after. Transactions are opened and closed in three places: the dispatcher around every command it runs, the insert session from the command that entered insert mode to leaving it, and one plugin edit request. A primitive called outside any transaction is its own transaction. The last closed transaction and the count of closed transactions are kept on the buffer as the hook the undo change will consume.
- Give every buffer a stable integer id, assigned from a counter the buffer list owns when the buffer first enters the list.
- Derive the modified flag from the change counter: a buffer is modified when its counter differs from the counter at the last load, reload, or save. `SaveFile`, the reload, and the plugin host stop writing the flag; the reader `modified` keeps its name.
- Record review findings that belong to later changes in `docs/backlog.md`: motions taking the whole editor state and writing `last_find`, ex ranges, the sentence scan over the whole buffer, scrolling rewriting every row, the test doubles compiled into the binary, and signs that do not follow inserted or deleted lines.
- Update `CLAUDE.md` and `docs/architecture.md` with the edit path, the new files, and the coding convention for edits.

Out of scope: undo, redo, the undo tree, and the dot command (roadmap item 4); marks and highlight states that will follow inserted and deleted lines with the same splice helper; shifting signs when lines are inserted or deleted (recorded in the backlog); a piece table or rope; and the backlog items listed above.

Assumptions recorded here rather than asked:

- A buffer's id is assigned when it first enters the buffer list, not when the value is constructed, because buffers are built in several use cases and only the list owns a counter; a buffer that was never listed has the id 0. The id never changes afterwards, also when the buffer leaves the list and comes back.
- The dispatcher opens a transaction for every action it runs, ex commands from the command line included, so `:e!` is one transaction; a command that ends in insert mode on the same buffer leaves its transaction open as the insert session, and leaving insert mode closes it. A transaction that holds no record when it closes is discarded and not counted.
- A plugin edit request made while a command's transaction is open on the same buffer, from an action bound to a key, joins that transaction, so one key stays one transaction; a request made outside a command, from an event, is a transaction of its own.
- When a plugin deletes the file of an open buffer, the buffer no longer matches any saved text, so the host marks it unsaved through the buffer (the saved change number becomes one no counter reaches) instead of writing the flag.
- A scratch buffer's lines replaced by its plugin count as one change and leave it unmodified, as before.
- Changing the text back by another edit leaves the buffer modified, as Neovim does without undo.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `text-buffer`: the replace primitive counts as one change, a reload primitive is added, the modified flag is derived from the change counter instead of being set by each primitive, and every edit produces a change record grouped into a transaction per command, insert session, or plugin edit request.
- `plugin-host`: reloading the current buffer delivers `buffer_change`, since a reload now changes the text through the buffer's primitives.

## Impact

- Domain: `carat/domain/buffer.rb` (the splice, `reload`, the derived modified flag, the id, and the transaction hooks), the new `carat/domain/line_splice.rb`, `carat/domain/change_record.rb`, and `carat/domain/transaction.rb`, and `carat/domain/editor_state.rb` (the id counter).
- Use cases: `carat/use_cases/dispatcher.rb`, `carat/use_cases/leave_insert.rb`, `carat/use_cases/files/open_file.rb`, `carat/use_cases/files/save_file.rb`, and `carat/use_cases/plugins/plugin_host.rb`.
- Tests: the new `test/domain_edits.rb` and `test/editor_transactions.rb`, a new rule in `test/lint.rb`, and the existing tests that wrote `modified` or `lines` directly, which now use `mark_saved`, `mark_unsaved`, and the primitives.
- Docs: `CLAUDE.md`, `docs/architecture.md`, and `docs/backlog.md`.
- No new dependency, no change to the configuration, the key bindings, or the plugin API.
