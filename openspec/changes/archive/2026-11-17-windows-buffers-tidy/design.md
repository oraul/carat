# Design

## Context

Two small behavior fixes in the buffer list and four comment corrections. The listing and E162 keep their shape; only a name holding a control character reads differently.

## Decisions

### Caret notation in ControlText

`ControlText.caret(text)` walks the bytes and replaces each C0 control with `^` and the character 64 above it (`^J` for a line feed, `^@` for NUL) and DEL with `^?`, the rest copied as it is, so UTF-8 names stay intact. This is Neovim's `transstr` for a name and the notation `:registers` already uses for a line break. `ControlText` is the domain module for text from outside made safe for the screen, which a file name is; `Messages.unsaved_buffer` and `ListBuffers#name_of` both call it, so the escape lives in one place. A scratch buffer's title goes through it too, as `:ls!` shows it in the same quoted column.

The padding to column 40 is measured after the escape, so `^J` counts its two cells.

### Injected tabs

The three use cases gain `tabs:` and an `attr_reader :tabs`, the shape of `CloseTab`. `EditorAssembly` passes `@tabs`; the two test builders pass the `tabs` they already hold. `test/adapters_assembly.rb` adds the three holders to "the tab list" check, which fails on a holder of another instance.

### Comments

Each stale comment is rewritten to what the code does: `BufferList#release` keeps every file buffer listed, hidden, and removes only a scratch buffer no window shows; the row under a stacked window is its separator row; `display_name` is what the status bar and the winbar show.

## Risks

- A name with a control character now reads differently in `:ls` and E162; no other message changes. Tests cover both.
