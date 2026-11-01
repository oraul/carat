# Design

## Context

See proposal.md for the motivation. `edit-pipeline` left every buffer edit going through one private `Buffer#splice` that records a `ChangeRecord` (buffer id, row, removed lines, inserted lines, sharing the strings with the buffer) in the open `Transaction`, opened by the dispatcher around every command, kept open as the insert session until `LeaveInsert`, and opened by the plugin host around an edit request. `Buffer#close` keeps the closed transaction in `last_transaction`, counts it in `closed_count`, and pushes a change notice with the transaction's span to the `BufferFeed`, from which the tab list clamps cursors and the plugin host makes `buffer_change`. `modified?` is `changes != saved_change`.

The grammar produces a `Command` (register, count, operator, action, char, linewise, keys); the dispatcher finds the handler in the `ActionTable` and runs it. Typed text in insert mode reaches `InsertText#call` straight from `HandleKey#insert_literal`; insert-mode actions (`insert.newline` and the rest) and the cursor keys go through the dispatcher. `Registers` holds the unnamed register and `a` to `z`; `Operate` and `OperateOnSelection` call `Registers#write`. The message row is one row; `Reporting#report` writes `EditorState#show`.

Spinel facts that shape the code (from the earlier designs and `CLAUDE.md`): `Array[Array[T]]` and arrays of non-builtin types are not pinned, so a list of records is `Array[untyped]` behind an accessor that declares the type; an `Array[untyped]` of `Data` values leaks `untyped`; a local holding two types widens a method for the whole program; methods of a `Data` instance read from a `Hash` member cannot be reached by dynamic dispatch; block-form `Data.define` and `Struct.new` ignore inline RBS; empty array literals are `Array[Integer]` unless stored through a writer after `super()`; `Array[Symbol]` is not pinned; concern method signatures are not applied.

## Goals / Non-Goals

**Goals:**

- Neovim's undo tree semantics for `u`, `<C-r>`, `U`, `g-`, `g+`, `:undo`, `:redo`, `:undolist`, `:earlier`, `:later`, with its messages.
- Undo and redo through the edit path, visible to every observer, creating no state.
- Memory proportional to the lines changed; `undolevels` trimming.
- The dot command over every change command, with counts and numbered registers.
- The numbered, small delete, black hole, and read-only registers and `:registers`.
- Undo and redo of one line on 100,000 lines under 50 us of key handling; `.` within 20 percent of the command it repeats; ordinary keys within 10 percent of `main`; allocations per key under the CI budget.

**Non-Goals:**

- Time and file-write arguments of `:earlier` and `:later`, persistent undo, `:undojoin`, `-- More --` paging.
- A different line store; the tail move of `LineSplice` stays as measured by `edit-pipeline`.

## Decisions

### The undo tree is a flat table indexed by sequence number

`Domain::UndoTree` is a `Struct` record per buffer, the member `undo` of `Buffer`. A state is a closed transaction with a sequence number; numbers start at 1 and are never reused, so a state's number is its time order. The tree keeps parallel arrays indexed by `seq - base`, where `base` is the number of the oldest kept slot: `parents` (the number of the state the change was made on, the root's number for the root's children, -1 for a dropped slot), `heads` (the child `<C-r>` follows, -1 for none), `children` (the count of live children), `depths` (changes from the original text, the `changes` column of `:undolist`), `saves` (the write number, 0 for none), `times` (Float seconds when the state closed), and `transactions` (`Array[untyped]`, read through `transaction_at(i) -> Transaction`). The root is not a slot: `root` is its number (0 until trimming merges states into it), with `root_head` and `root_children`. `current` is the number of the state the text shows, `last` the highest number given, `saved` the number of the state at the last write (-1 for none), `pending_save` the write number owed to a transaction still open, `save_count`, and `live`. All members are `Integer`, `Float`, or arrays of them, which Spinel pins; only the transactions are untyped behind their accessor.

A flat table rather than a record per state keeps every walk over integers, as `Layout`'s node table does, and a number's slot is found by subtraction, not search.

- `push(transaction, now, levels)`: gives the next number, with `current` as parent and depth one more than the parent's, makes it the parent's head, counts it as a child, makes it current, and trims.
- `undo_step` returns the transaction to revert and moves `current` to its parent, leaving the parent's head on it so `<C-r>` comes back; `redo_step` takes the head of `current`. `undo_seq` and `redo_seq` say what the next step would be, -1 for none.
- `path_to(target, out)`: fills `out` with the steps from `current` to `target` as signed numbers, negative to undo and positive to redo: it walks both ends up by their parents, the higher number first, until they meet (a parent's number is always lower than its child's), undoing on the way up from `current` and redoing the other side's states in reverse. A redo step makes the walked child the parent's head, so `<C-r>` and `u` then follow the branch `g-` and `g+` arrived on, as Vim's alternate pointers do.
- `nearest(target, older)`: the live state at or before (or after) `target`, the root when none, for `g-`, `g+`, `:earlier`, and `:later` over trimmed numbers.
- Trimming at `undolevels`: while more states live than `levels`, the oldest live state goes. When it is on the path to `current` (the root has only that child, or the walk up from `current` passes it) it merges into the root: the root takes its number, head, and child count, and every other child of the old root is dropped with its descendants. Otherwise it is dropped with its descendants, as Vim frees the oldest branch. Dropped slots at the front are removed with `shift`, so an ordinary trim costs one shift of each array; a descendant scan runs only when a branch goes. `levels` of 0 keeps no state; negative values are refused by `Options` already.
- `leaves`: the states without children, in number order, for `:undolist`.

The tree also keeps the line `U` restores: `line_row` (-1 for none), `line_text`, and `line_col`.

### Applying a state goes through the splice

`Buffer#revert(transaction)` splices each record back, last first (rows `row` to `row + inserted.length` become `removed`); `Buffer#reapply(transaction)` splices each record forward. Both call the private `splice`, so the line array changes only there, the change counter counts every step, signs move, and the records land in the open transaction. The `Undo` use case first closes any transaction open on the buffer, then opens one marked `history`, applies every step of the command (`3u`, a `g-` walk) inside it, and closes it with the cursor where it comes to rest: `Buffer#close` sends the history transaction's span to the feed as a change notice, so the tab list clamps cursors and plugins see `buffer_change` with the rows, but does not push it to the tree. The dispatcher's own transaction for the `u` key is already closed by then and closing it again does nothing.

Neovim's cursor rule after undo and redo: the cursor goes to the first changed row of the topmost record, or to the cursor before the change when that row is inside the record's rows; one row up when that leaves it one below the cursor before the change (the `o` case); then the column before the change when the row is the one the change started on, the first non-blank otherwise; past the end, the last line at column 0.

The message counts lines as `u_undo_end` does: the lines the steps removed minus the lines they put back, with a buffer of one empty line counting as no line (Neovim's empty-buffer flag), gives `N more lines`, `1 more line`, `1 line less`, or `N fewer lines`; zero gives `N changes` (or `1 change`) with the number of lines put back. Then `before #N` with the last undone state's number, or `after #N` with the last redone one's (for `:undo N` the state reached), and the time of that state as `N seconds ago` (`1 second ago`), two spaces before it.

### Saved state and the modified flag

The counter stays the source of `modified?`. `Buffer#mark_saved` also tells the tree: the saved number is `current`, or, while the open transaction has records (the `:e!` reload, which marks saved inside the command's transaction), the number that transaction will get, `last + 1`, which `push` gives it. After applying states, the buffer calls `mark_saved` again when the tree's `current` is the saved number, and the counter has moved past `saved_change` otherwise, so the flag clears on returning to the write and sets on leaving it. `mark_unsaved` sets the saved number to -1. A trimmed saved state never matches again, as in Vim.

### Records on one line are merged

Typing in insert mode makes a record per key, each holding the whole line before and after. `Transaction#add` merges a record into the previous one when its removed rows lie inside the previous record's inserted rows, replacing those rows of the previous record's inserted list in place: a session of typing on one line keeps one record, the line before the session and the line after, as Vim saves a line once per undo state. Records made before a mark (`Buffer#transaction_mark`, which the plugin host takes before applying an edit request so it can still revert to it) are never merge targets. The inserted lists are built by each primitive for its call and are not shared, so changing them in place is safe; the line strings themselves are never changed.

### Time and undolevels reach the buffer through the feed

`BufferFeed` gains `now` (Float seconds) and `undolevels`. The dispatcher, which now receives the clock port and the feed, sets `now` before each command; the assembly sets `undolevels` from `Options#undolevels` (default 1000, read from the configuration's `options`). `Buffer#close` pushes a non-history transaction of a listed file buffer into its tree with the feed's time and levels; an unlisted buffer uses level 1000 and time 0, and a scratch buffer pushes nothing. This keeps the domain free of ports, and every transaction, including a plugin's from an event, gets a time.

### The U line

When a non-history transaction is pushed, `UndoTree#note_line` looks at its records: all on one row and replacing one line by one line, it saves that row's line before the transaction (the first record's removed line) and the column of the cursor before when it was on that row, unless that row is already saved; a record that inserts or removes lines forgets the saved line. `U` (`Undo#line`) replaces the saved row's text with the saved text through `set_lines`, keeps the replaced text as the new saved text (so `U` undoes `U`), and puts the cursor at the saved column. It runs in the dispatcher's transaction, so it is an undo state of its own; since it changes the saved row, `note_line` keeps the swapped text.

### The dot command records commands, not keys

`Domain::LastChange` is a `Struct` record shared by the dispatcher, `InsertText`, `LeaveInsert`, and `RepeatLast`: the `Command` of the last change, whether it ran in a visual mode and the size of its selection (kind, rows, columns or display columns, whether `$` reached the line ends), and its insert session as parallel lists `steps` (action names, `""` for typed text) and `texts`, plus `recording` while that session is open, `restart` after an arrow key, `inserted` (the text for `".`), and `replaying`.

Recording: the dispatcher records a command that started in normal, operator-pending, or a visual mode when its handler is a change handler (`ActionHandler#repeat`, a constructor keyword every handler now passes) and it either made records in its transaction or left the editor in insert mode. A visual command's selection size is measured before the handler runs. A command that ends in insert mode starts recording its session. `InsertText` appends typed text and the insert actions (newline, backspace, delete, tab) while recording, and keeps `inserted` as the net text; `LeaveInsert` stops recording and stores `inserted` for the `".` register. Handlers that are not changes: motions, yanks (`y` makes no records anyway), mode switches, windows, tabs, messages, plugin actions, the command line, undo, redo, `U`, and `.` itself.

Keys were the alternative (Vim's redo buffer): replaying them through `HandleKey` would need `HandleKey` to reach itself from a handler, would run the keymap and the grammar a second time, could not rebuild a visual region of the same size, and would follow a remap that changed since. A recorded command runs the handler directly, which is also what keeps `.` within the cost of the original.

Replay (`RepeatLast`, the handler of `history.repeat`): nothing when no change is recorded. A typed count replaces the recorded count, and is stored; a recorded register `"1` to `"8` is incremented and stored. For a visual change the anchor is set at the cursor and the cursor at the far end of a region of the recorded size (lines; characters on one line; the end column for several lines; display columns for a block, or the line ends with `$`), the mode set to the recorded kind, and the handler run, which leaves visual mode as always. Then, when the command left insert mode open, the recorded steps run through `InsertText` and the insert action handlers with `replaying` set, so nothing is re-recorded, and `LeaveInsert` ends the session, repeating a block insert as the original did. All of it runs inside the dispatcher's transaction for `.`, which closes as one undo state.

An arrow key in insert mode: the dispatcher sees a motion handler in insert mode, closes the session's transaction so far (an undo state), runs the motion, and opens a new transaction; `LastChange` stops recording and sets `restart`, so the next typed text starts a new change, `i` with that text, as Neovim's `start_arrow` does.

### Registers

`Registers` keeps `unnamed`, `named` (`a` to `z`), `numbered` (`Array[untyped]` of ten entries or nil, read through `numbered_at`), `small` (`"-`), `inserted` (`".`), and `command_line` (`":`). Writes are named by what made them:

- `yank(name, entry)`: nothing for `_`; the named register (with uppercase append) or, when none is named, `"0`; and the unnamed register.
- `delete(name, entry, big)`: nothing for `_`; the named register when one is named; when `big` (linewise, more than one line, or a motion among `( ) { }`) shift `"1`..`"8` down to `"2`..`"9` and write `"1`; otherwise `"-` when no register is named; and the unnamed register.
- `read(name)`: the unnamed register for `""` and `"`, the named, numbered, `-`, `.`, and `:` registers; nil for `_`, `/`, and an empty one. `"%` is read through `read_with_file(name, path)`, which the put paths and `:registers` use with the current buffer's path.
- `Registers.valid_name?` accepts `"`, letters, digits, and `- _ . : % /`; `Registers.read_only?` is true for `. : % /`.

`Operate` and `OperateOnSelection` call `yank` and `delete` instead of `write`; an operator or a visual command that would write a read-only register returns `E354: Invalid register name: '.'` before touching the buffer. `EditCommandLine#execute` stores the executed line for `":`.

`:registers` and `:display` (`RegisterCommandHandler`) build Neovim's listing: the line `Type Name Content`, then one line per register holding text in the order `"`, `0` to `9`, `a` to `z`, `-`, `.`, `:`, `%`, each as two spaces, the type `c`, `l`, or `b`, two spaces, the quote and the name, three spaces, and the text with each line break shown as `^J` (one after a linewise entry), cut to the screen width minus 11. A name list as argument keeps only those registers.

### A message of several lines

`:undolist` and `:registers` report a message with `"\n"` between its lines. `FramePresenter#paint_message` paints such a message over the rows above the message row, its last lines when it is taller than the screen, and `Press ENTER or type command to continue` in the message row with the cursor after it; the rows are compared cell by cell like the rest of the chrome, and the frame's layout key and painted-row record are dropped, so the next two frames repaint every window row and the screen presenter compares every row. In `HandleKey#step`, a key arriving while such a message shows clears it; Enter and Space are then consumed, as at Neovim's hit-enter prompt, and any other key is handled as usual.

### New handlers and names

- `HistoryHandler < ActionHandler` with variants for `history.undo` (`u`), `history.redo` (`<C-r>`), `history.undo_line` (`U`), `history.older` (`g-`), `history.newer` (`g+`), and `history.repeat` (`.`), all with `repeat: false`.
- `EditHandler` gains `operator.replace_char` (`r{char}`, kind `:char`) and `operator.toggle_case` (`~`) through `Operate#replace_chars` and `Operate#toggle_case`: count characters from the cursor, none when fewer remain for `r` (Vim beeps), the cursor on the last replaced character for `r` and after the toggled ones for `~`.
- `HistoryCommandHandler < ExHandler`: `u[ndo]`, `red[o]`, `undol[ist]`, `ea[rlier]`, `lat[er]`; `RegisterCommandHandler`: `reg[isters]`, `di[splay]`. Registered after the tab commands and before the plugin commands.
- The `Undo` use case (`carat/use_cases/undo.rb`) holds the tree walks, the cursor rule, and the messages for every one of these; `RepeatLast` (`carat/use_cases/repeat_last.rb`) the replay. Architecture section 5.1 named `Undo`, `Redo`, and `RepeatLast`; redo is a method of `Undo` because both share the walk and the message, and the document is updated.

## Risks / Trade-offs

- [A record's inserted list changed in place by a merge is shared elsewhere] → Every primitive builds the list for its call; `splice` keeps it only in the record; the merge never touches a record before the transaction's mark. The domain test checks a merged record and the buffer after undo.
- [Dropping a branch at trim time scans the table] → Only when a branch goes; the linear case shifts each array once. At 1,000 states that is a few microseconds.
- [The dispatcher now does more per command] → A clock read, a handler flag test, and two integer comparisons for ordinary keys; the recording work runs only for change handlers. Measured against `main`.
- [A plugin or a mapping edits between a command and `.`] → `.` repeats the recorded command on the current text, as Vim's redo buffer does.
- [Interaction of `U` with undo] → Undo and redo leave the saved line; a row past the end makes `U` do nothing, as Vim's beep.

## Migration Plan

None: no data or plugin API change. The new `undolevels` option has a default; a configuration without it keeps 1000. Rolling back is reverting the squash commit.

## Measured result

To be filled in from `make bench` once the implementation is complete.
