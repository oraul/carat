# Design

## Context

`SetCommandHandler` (`carat/use_cases/ex/set_command_handler.rb`) handles `filetype`, `syntax`, and five flags through three parallel `case` switches, and answers the other options of `PENDING` with Not implemented. `Options#apply` (`carat/domain/options.rb`) checks and stores one `option.*` line: the kind through `RcValue.valid?`, then a per-name rule (a range through `bounded`, a known word through `named`, `listchars?`), noting the problem on the `Config`. Every option the frame and the use cases read is read from `state.options` at each use, but for `undolevels`, which `EditorAssembly` copies once into the `BufferFeed` whose `undolevels` each buffer reads when it records an undo state, and `startscreen`, which only the startup reads.

## Goals / Non-Goals

Goals: one rule per option for both paths, so `:set` cannot store what a line refuses; a table of handled options that the setting, the showing, the resetting, and the listing all read; the existing flags and `filetype`/`syntax` kept as they behave.

Non-goals: local options; `theme` and `background` (colorscheme-command); the options outside `PENDING`.

## Decisions

- Split `Options#apply` into `problem(name, key, word)`, the message a line would note or "" (the range, the known word, the listchars and guide character rules), and `assign(name, word)`, the store; `apply` keeps the kind check and calls both. `:set` builds the configuration word of its result (the number's `to_s`, the word as typed), checks it with `RcValue.valid?` and `problem`, and only then calls `assign`. Alternative: a second set of range checks in the handler; refused, since the two would drift, which is what the acceptance rule forbids.
- `Options#value_of(name)` gives the current value as a line words it ("true", "8", "rounded"), which `name?`, the listings, and the comparison with the shipped defaults read; `Options.shipped` builds the options of `config/default.caratrc` alone. `EditorAssembly` builds the shipped options once and hands them to the handler, with the `BufferFeed` for `undolevels`.
- The handler keeps one ordered table of the options it handles, full name to short name (`NAMES`), and reads each one's kind from `Options::KINDS`; the flags' three switches go, since `assign` and `value_of` serve every option. `filetype` and `syntax` stay buffer options handled as before.
- An argument is split at unescaped blanks, `\ ` and `\\` kept as a blank and a backslash, as Vim reads `:set`. The operator is found from the first `=` (with a `+`, `-`, or `^` before it) or a trailing `?`, `&`, or `!`; a `no` or `inv` prefix is read only when the rest names an option, so `number` is never read as `no` + `mber`.
- Refusals are Neovim's codes: `E521` for a number that does not parse (one to nine digits, an optional minus), `E474` for every other refused value or form, `E518` for an unknown name; Not implemented answers (`theme`, `background`, `startscreen live`, a word's `+=`) are messages, not errors, as the handler's are today.
- After a store the handler runs the side effects the old switches ran (the case options compile the last pattern again, `hlsearch` on shows the matches again) and copies `undolevels` into the feed. `startscreen` answers `Not implemented: :set startscreen live` before any store.
- The frame presenter and `ArrangeView` read every option at each frame and arrange (the gutter width from `Window#gutter_width`, the tab width, the winbars), so no cache needs telling; the editor test of each live scenario proves it through the harness's real frame.

## Risks / Trade-offs

- A multiplied number is computed in a 64-bit integer from two numbers of at most nine digits, so it cannot overflow before the range check.
- The bare `:set` listing compares with the shipped defaults, so the test configuration's own lines (`option.showtabline 1`) show in it; the tests expect that.
- Lane overlap: the backlog lane's config-guards-b edits the same handler line; a merge of main resolves it by hand.
