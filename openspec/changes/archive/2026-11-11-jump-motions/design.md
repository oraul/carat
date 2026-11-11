# Design

## Context

The window's jump list (`Window#jumps`, `JumpList#push`) is filled by `VisitTarget#jump` (`gd`) and `BufferList#enter` (every buffer switch) only. Cursor motions resolve in `Domain::Motions.for_command`, applied by `Move` (normal and visual modes) and by `Operate#operand` (under an operator); searches move in `JumpToMatch` and resolve under an operator in `Operate#search_motion`; a range alone moves in `ExecuteEx#go_to`. No alternate buffer exists, `%` has no motion, and key notation reads no `<C-6>`.

## Goals / Non-Goals

Goals: every jump form of the queue item adds one entry as Neovim's `setpcmark` does; the window's alternate buffer with `Ctrl-^`, `Ctrl-6`, and `:e #`; the `%` motion the acceptance names.

Non-goals: the `#` flag of `:ls`, `#` outside `:e #`, marks, `[[`, `]]`, `:s` and `:tag` as jumps, `:jumps`, moving the jump actions out of `DefinitionHandler`.

## Decisions

### The motion names say which motions jump

`Motions::JUMP_NAMES` lists `cursor.buffer_start`, `cursor.buffer_end`, the sentence, paragraph, and screen motions, and `motion.match_pair`, and `Motions.jump?(action)` answers from it, beside `Search.action?` for the searches. The callers that move decide when to record: `Move` after a motion resolved, `Operate#operand` after the operand's motion resolved (motion or search), `JumpToMatch` after a hit, `ExecuteEx#go_to` after the range resolved. Recording in the dispatcher instead was the backlog's outline, but the dispatcher does not know whether the motion failed, and a failed jump records nothing in Neovim. A flag on `Motion` would need every motion's constructor to carry it; the names are one list next to `NAMES`.

### Window#record_jump

`Window#record_jump` pushes the window's buffer and cursor, skipping buffer 0 (the startup buffer, which no walk finds), so the four callers share one rule; `gd` keeps its own push, which records a position read before the open.

### The alternate buffer is a window member set by the buffer switch

`Window` gains `alternate`, a buffer number (0 for none), as Neovim keeps `w_alt_fnum` per window. `BufferList#load`, the one place a window changes buffer by a switch (`enter` and the jump walk call it), sets it to the buffer left unless that buffer had number 0 or the startup buffer gave its number to the target. `copy_from` (a split) and `OpenTab` copy it with the jump list. `BufferList#alternate_of(window)` answers the listed buffer or nil, so a deleted alternate buffer reads as none.

### Ctrl-^ is a buffer switch, :e # an edit by name

`Ctrl-^` is the action `buffer.alternate`, a `BufferHandler` variant that asks `SwitchBuffer` for target `:alternate` (or `:number` with a count), so it shares `:b N`'s `E37` refusal and records the jump through `enter`; `E23` is `SwitchBuffer`'s when no alternate exists. `:e #` substitutes the alternate buffer's path in `FileCommandHandler#edit` before the existing checks, so it is `:e name` with its message, Neovim's expansion of `#`; the handler takes the buffer list to read it. `E194` and `E499` are Vim's expansion errors.

### % scans bytes

`%` finds the first bracket byte at or after the cursor's byte offset and walks bytes across lines counting the pair's depth: a bracket is ASCII, which never appears inside a UTF-8 sequence, so the walk needs no character slicing (the open `line[i, 1]` note of `docs/spinel-notes.md`); the cursor column converts to and from a byte offset once on each end. `{count}%` is `to_row` of `(count * lines + 99) / 100 - 1`.

### Key notation

`KeyNotation.control_code` reads `6` as 30, as Vim reads `<C-6>`, and `format` spells codes 28 to 31 with their Vim names (`<C-\>`, `<C-]>`, `<C-^>`, `<C-_>`) instead of adding 96, which gave `<C-~>`. The binding is `<C-^>` alone, since both keys arrive as code 30.

## Risks / Trade-offs

- An unbalanced bracket in a large buffer makes `%` scan to the buffer's end, as Vim's does; the scan is bytes only and allocates nothing per byte.
- `n` repeated through a file now fills the list with one entry per match line, as Neovim's does; the limit of 100 holds it.
