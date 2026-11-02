# Design

## Context

See proposal.md for the motivation. What the code has today and what shapes the approach:

- Frames are three flat `Array[Integer]` arrays (code point, width, highlight id); `Highlight` holds ten editor ids, and `ScreenPresenter#sgr` maps them to fixed SGR strings (reverse video for the status line, yellow numbers).
- Every edit goes through `Buffer`'s private splice, which records a `ChangeRecord` and moves the sign layers with `LineSplice.shift_marks`; lines are never mutated in place, so a line string's identity stands for its text (the render-core line cache relies on it).
- The frame presenter repaints a window row only when what it shows changed, by comparing the inputs of each segment in `PaintedRows`, the line by identity.
- `ArrangeView` runs before every render; the assembly's `render` then calls the frame presenter, which only reads the state.
- Plugins are registered from a generated list, every call into one goes through `Guarded`, and the API is 1.2.
- Spinel facts that constrain the data shapes: `Array[Array[T]]` pins are not applied, an `Array[untyped]` of `Data` values leaks `untyped` unless read through a typed accessor, an empty array literal held in a local and passed to another method is copied, a pinned hash or array member refuses an empty literal passed to a constructor, and a method of a `Data` instance read from a `Hash` member cannot be reached by dynamic dispatch.

## Goals / Non-Goals

**Goals:**

- Highlighting that costs a highlighted 10,000-line file less than 0.25 ms per key and fewer than 100 allocations per key for `l h` and `j`, never tokenizes rows below the screen, and re-tokenizes after an edit only until the state settles.
- A tokenizer interface that passes no per-token object across the plugin boundary, so one API can later serve process plugins.
- Colors from a theme for every group, the editor's included, at the depth the terminal supports.

**Non-Goals:**

- Highlight ranges and virtual text requested by plugins, `:colorscheme`, user theme files, other languages, and the rest of `:set` (all in `docs/backlog.md`).
- A Ruby parser: the tokenizer is a line scanner with the heuristics editors use (vim-ruby's groups, its regular expression and heredoc rules).

## Decisions

### 1. The engine is core, each language a plugin

The filetype table, the group table, the themes, the syntax cache, and the drawing are core; the tokenizer of a language is a plugin that declares its filetypes in its manifest. The alternative, tokenizers as adapters under `carat/adapters/tokenizers/` as section 8.2 of the architecture first said, would make every language a change to the core and give third parties no way in; the user chose the plugin form. Section 8.2 and 9.1 are rewritten accordingly.

### 2. Tokens are integer triples appended to a host array; the state is an integer

`Plugin#tokenize(filetype, text, state, tokens)` appends `start, length, group` triples in code point columns to `tokens` and returns the end state. Alternatives: a token object per token (one allocation each, and a `Data` array leaks `untyped`), or a response value holding tokens and state (one more allocation per line and an `Array[Integer]` inside a `Data` that a process plugin would encode anyway). The host clears and reuses one array and one text string per call (`String#replace`, no allocation); it copies the triples into the cache only for a row it keeps, validating each (non-negative start, positive length, an id among the syntax groups), which is the boundary copy. The state is an opaque non-negative integer: the host only compares states for equality and passes them on, so a plugin can pack whatever it needs. Group ids are resolved by name once, in `activate`, with `Host#syntax_group`, so no string travels per token; a plugin that resolved nothing draws plain.

The text is a copy the host reuses: valid during the call only, documented in `docs/plugins.md`. This keeps the boundary rule (the plugin never holds the buffer's own string) without an allocation per tokenized line.

### 3. Highlight ids: editor groups first, syntax groups after

`Highlight` keeps the editor ids 0 to 9 as they are, adds `SIGN_COLUMN` (10), and numbers the thirty syntax groups from `SYNTAX_FIRST` (11) in the order of Neovim's `:help group-name`, with `NAMES` indexed by id and `COUNT`. `syntax_group` answers only syntax names, so a plugin cannot paint a token as a status line. Ids are integers, so a frame stays three integer arrays and a theme is a few integer arrays indexed by id.

### 4. Filetype on the buffer, syntax name beside it

`Domain::Filetype.detect(path, first_line)` holds the table: extensions, whole names, then a shebang whose program (directly or after `env`, skipping `env`'s options) is `ruby` optionally followed by a version. `Buffer` gets `filetype` and `syntax` (the name that chooses the tokenizer, set with the filetype, changed alone by `:set syntax`), detected in `initialize` and again by `rename`. Detecting on construction covers `:e`, splits, tabs, and the plugin requests that open files, which all build buffers through `Buffer.from_text`; a scratch buffer has no path and no filetype.

### 5. The syntax cache: end states per row, tokens per line identity

Each buffer holds a `SyntaxCache` (a `Struct` record) with:

- `ends`, an `Array[Integer]` of the end state of every row tokenized so far (its length is the frontier, the rows ever reached), `-1` for a row whose text changed since;
- `valid`, the rows `[0, valid)` whose end states are known to be right;
- `dirty_to`, the row after the last row changed since `valid` last passed it;
- two `SyntaxTable` generations of `SyntaxLine` values (text, start state, tokens, end state) keyed by the identity of the line string, a sibling of `IdentityTable` because Spinel types the entry accessor once;
- `owner` and `name`, the plugin and syntax the contents came from, so a changed filetype, `:set syntax`, or another plugin taking over resets the cache.

The buffer's splice calls `shift(row, removed, inserted)`, the integer sibling of the sign layers' shift: it moves `ends` with `LineSplice.shift_marks`, marks the inserted rows `-1`, lowers `valid` to the row, and extends `dirty_to` over the inserted rows (shifting a later one). An edit that reaches the frontier truncates `ends` there. Undo and redo go through the same splice, so they invalidate the same way.

Advancing row `k` (only ever `k == valid`) stores its new end state and compares it with the state stored before: when they are equal, the old state was a real one, and `k + 1 >= dirty_to`, every row up to the frontier is consistent again (each was computed from its own unchanged text and the state before it), so `valid` jumps to the frontier. That is "until the stored end state matches again". The comparison needs no row after the last change, because a deletion leaves an unchanged row whose old state may still match.

The token tables are keyed by identity, as the line cache is, because a line string is never mutated: a row whose line object and start state are the same has the same tokens. The cache never holds tokens of a row off the screen; turning a generation once per frame drops a line no window showed in the last two frames. The `ends` array costs one integer per row reached, nothing for rows never shown.

Alternatives: tokens per row in a row-indexed array moved by every splice (a second shifted array of arrays, which Spinel cannot pin), or a state per row only and tokenizing every visible row every frame (60 calls per key where the cache needs none for a cursor move).

### 6. HighlightView, a use case run before every render

`UseCases::HighlightView` runs in `EditorAssembly#render` after `ArrangeView` and before the frame presenter. For each window of the current tab page it finds the tokenizer through the plugin host (`PluginSyntax#provider`, the first enabled plugin declaring the syntax), drops the cache when there is none or syntax is off, then advances `valid` to the window's last visible row, tokenizing rows above the window for their end states only, and makes sure every visible row's `SyntaxLine` is in the current table, tokenizing a miss. A visible row met while advancing that is already in the table is not tokenized again: its stored end state is used. It counts the rows it tokenized, which the benchmark reports. The frame presenter stays a pure reader: it looks a visible row up with `SyntaxCache#lookup(row, line)` and paints the triples into the frame's highlight array over the text it painted, before the selection.

`PaintedRows` records the `SyntaxLine` each segment was painted with (by identity, a sentinel for none), so a row whose highlight changed without its line changing, as below an opened string or after `:syntax off`, is repainted and marked dirty.

The tokenizer call goes through `Guarded` in `PluginSyntax`, part of the plugin host; a plugin that raises is disabled by the registry as for every other call, `tokenize` reports the failure, and `HighlightView` drops the cache in the same render, so the frame that shows the message is already plain.

### 7. The Ruby tokenizer's state encoding

The plugin scans bytes (no substring is made per token; keywords are recognized by a 48-bit polynomial of the identifier's bytes in a table, confirmed byte by byte) and converts byte offsets to code point columns through a reused map only for a line with non-ASCII bytes. Within a line it keeps a stack of up to eight open string frames. At the end of a line the open constructs are packed into one integer of at most 58 bits:

| Bits | Field |
| --- | --- |
| 0-1 | mode: 0 code, 1 inside `=begin`, 2 after `__END__` |
| 2-3 | number of pending heredocs, 0 to 2 |
| 4-13, 14-23 | each heredoc: terminator number (1-255, from the plugin's table of terminators), indented (`-` or `~`), raw (single-quoted) |
| 24-25 | number of open string frames, 0 to 2 |
| 26-41, 42-57 | each frame, outermost first: closing delimiter byte (7 bits), interpolating, kind (string, symbol, regular expression), nesting depth of a paired delimiter (0-7), inside an interpolation, brace depth in it (0-3) |

A line that starts with heredocs pending is the body of the first; its terminator line removes it. The terminator strings live in the plugin's own table, interned in the order met, so equal text gives equal states, which is all the cache needs; a 256th distinct terminator is not recorded and its body is highlighted as code. A third string frame, a deeper nesting or brace depth, or a third heredoc is dropped at the end of the line (the frames kept are the outermost), which the spec calls degrading gracefully. An interpolation left open at the end of a heredoc body line ends with the line.

### 8. Themes and color output

`Domain::Theme` (a `Data` value with one method) holds, per group id, a 24-bit foreground and background (`-1` for the terminal's own), a 16-color foreground and background index (`-1` for none), and attribute bits (bold, italic, underline, reverse); `Domain::Themes` holds `carat-dark` and `carat-light` and `find(name)`. They are Ruby, not JSON: they are not key bindings, the configuration names a theme rather than defining one until user themes arrive with `options-and-config`, and a table in the domain is typed and needs no parsing at startup. The 16-color index is given by hand, as Vim themes give `ctermfg`, because the nearest of the sixteen colors to a pastel is white for most of them.

`Domain::ColorDepth.detect(colorterm, term)` decides the depth; `TerminalPort#colors` answers it, the `AnsiTerminal` driver reading `COLORTERM` and `TERM` once in its constructor (no other layer reads the environment). `Adapters::SgrTable.from_theme(theme, colors)` builds one SGR string per group once, at assembly, quantizing 24-bit colors to the 256-color cube or gray ramp for 256 colors; `ScreenPresenter` looks the string up by id instead of its `case`. `Normal` is `\e[0m`, so blank cells and the cleared screen keep the terminal's background.

### 9. Ex commands

`SyntaxCommandHandler` (`sy[ntax]`) switches `Options#syntax_on`; `SetCommandHandler` (`se[t]`) handles only `filetype`/`ft` and `syntax`/`syn`, with `Not implemented` for the options Carat already has and `E518` for the rest, so the rest of `:set` can grow in `options-and-config` without changing these answers. Both are registered after the register commands, before the plugin commands.

### 10. Benchmark

`bench/keys.rb` gets a text kind `ruby` (a generated block of about twenty lines with a comment and `TODO`, a module, a class, a constant in hex, a method with interpolation, a squiggly heredoc with interpolation, `%w[]`, a regular expression, a multi-line double-quoted string, instance and global variables, and a float), a plugin choice per scenario (none, explorer, or ruby), the time to the first frame (`open`), and the rows tokenized per key. Setup keys may name the line of a heredoc body (`H`) or of the middle line of a multi-line string (`S`).

## Risks / Trade-offs

- [`G` on a large file tokenizes every row above the end once] → it is what correctness needs with multi-line state; it happens once per region (the frontier stays), the benchmark reports it, and the backlog records a sync point option should it matter.
- [A typed `"` re-tokenizes every visible row below it, up to one screen] → bounded by the window height; rows below the screen are left for when they are shown.
- [Heuristics misjudge `/`, `%`, `?`, or `<<` in unusual code] → the same rules as vim-ruby, documented; the error is visual and local to the line.
- [Plugins built against 1.2 do not compile with the tenth manifest member] → all compiled plugins are in this repository and move with it; process plugins do not exist yet.
- [A plugin keeps the text it was given] → documented as valid during the call only; the plugin can dup it.
- [The terminal's background under `carat-light` on a dark terminal] → documented: the light theme is for light terminals.

## Migration Plan

None beyond the in-repository manifests; the configuration keys used already exist (`theme`) or are added with their defaults (`plugins.ruby`).
