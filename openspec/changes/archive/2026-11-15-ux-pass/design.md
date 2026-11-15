# Design

## Context

carat's UI goal (`docs/goals.md`, goal 1) is a pleasant UI and UX in its Facet design language: calm, readable, its own personality, never a copy of another editor. The gates check code, not use, so this change records a review of the real binary in use, with its screens as evidence, for sprint 9's planning. It changes no code.

## Goals / Non-Goals

Goals: review six topics from three views, save every screen the review cites with its colors, time key-to-answer, and append each finding the skeptic keeps to `docs/backlog.md` with a reproduction.

Non-goals: fixing a finding; a real language server; committing the driver (see the proposal's Out of scope).

## Decisions

### Method

- Binary: the release build of `make build` at the branch's base, `build/bin/carat`.
- Driver: a small program compiled with Spinel in a scratch directory, never committed, that spawns the binary in a pseudo-terminal of 24 rows and 80 columns as `test/smoke_editor.rb` does (`PTY.spawn`, `TERM=xterm-256color`, `COLORTERM=truecolor`, `HOME` a fresh directory), writes keys, drains the output until it is quiet for 0.4 s (0.25 s for the timing run), and feeds every byte to a small terminal model (cursor moves, erases, SGR colors, the cursor shape and visibility).
- Screen files: `screens/NAME.txt`, one per screen: a header with the keys written and the time to the first and last byte of the answer, the cursor's row, column, shape, and visibility, the 24 text rows (`NN|`), then the color runs of each row (`NN: start-end style;`, `fg=`/`bg=` as hex, `default` for the terminal's own colors).
- Fixtures: a project with `greet.rb` (a ten-line Ruby class), `notes.txt` (two lines), and a few files in subdirectories; an empty folder; a user `caratrc` naming a canned language server and trusting the project root (`language.ruby.lsp`, `language.trusted_roots`). The canned server answers `initialize` (after 4 s for the starting state, at once otherwise), hover with a Markdown signature, completion with three items, and `null` for anything else, so definition peek has no location.
- Key notation in the reproductions: `<Space>` is the leader, `<C-x>` a control key, `<CR>` Enter, `<Esc>` Escape; an Escape is always written alone, since Escape and a key written together read as one Alt key.

### The three views

- Facet: does the screen feel calm and readable, and is it carat's own, consistent with the rest of carat?
- Other tools: what Neovim (defaults, and common plugins such as a fuzzy finder) and VS Code show at the same moment.
- Skeptic: argues each finding away (a deliberate choice, the same in the tools users come from, not shown by the evidence); a finding stays only when the skeptic agrees it is a real cost to the user.

## Review

### Screens

- First use: `first-start` (no file, settled), `start-early` (no file, 100 ms in), `start-late` (one second later), `first-quit-hint` (`<C-c>` on the start screen), `first-file` (started on `notes.txt`).
- Empty and loading states: `empty-new-file` (started on a new `new.txt`), `empty-explorer` (`<Space>e` in the empty folder), `empty-explorer-help` (then `?`), `empty-finder-open` (`<C-p>`), `empty-finder-nomatch` (then `zzqx`), `empty-finder-nomatch-enter` (then `<CR>`), `lsp-starting` (started on `greet.rb`, the server not yet answering), `lsp-ready` (five seconds later).
- Feedback: `fail-up-at-top` (`k` on line 1), `fail-unbound-key` (`gZ`), `fail-ex-unknown` (`:frobnicate<CR>`), `fail-ex-unknown-later` (four seconds later, no key), `fail-ex-next-key` (then `l`), `fail-ex-range` (`:99,100d<CR>`), `fail-search` (`/nothere<CR>`).
- Messages: `msg-write` (`:w<CR>`), `msg-modified-quit` (`x` then `:q<CR>`), `msg-leader-wait` (`<Space>`), `msg-leader-menu` (one second after it); the feedback screens above also show messages.
- Floats, from `greet.rb` with the cursor on `greet` (`3Gw`): `float-hover` (`K`), `float-hover-esc` (`<Esc>`), `float-hover-q` (`K` then `q`), `float-completion-lsp` (`8G`, `o`, `gre`), `float-completion-esc` (`<Esc>`), `float-completion-keyword` (`o`, `gr<C-n>`), `float-peek` (`<Space>dd`), `float-peek-esc` (`<Esc>`), `float-palette` (`<Space>p`), `float-palette-filter` (then `wri`), `float-palette-esc` (`<Esc>`), `float-buffers` (`<Space>bb`), `float-buffers-esc` (`<Esc>`), `float-finder` (`<C-p>`), `float-finder-esc` (`<Esc>`).
- Time: `time-motion` (`j`), `time-insert-char` (`i` then `x`), and `timings.txt`, five runs of each measured key.

### Key-to-answer time

| Key | First byte | Settled | Note |
| --- | --- | --- | --- |
| `j` (motion) | 0.3 to 2.6 ms, 0.6 typical | same | one write per frame |
| `x` in insert | 0.4 to 1.3 ms | 143 ms on the first only | a second frame about 140 ms later after the first edit, the language server's change |
| `K` (hover) | 0.4 to 0.7 ms | 41.4 to 41.7 ms | the float about 41 ms after the key with a server that answers at once |
| completion (`gre`, `gr<C-n>`) | 0.6 ms | 143 ms | the popup's last frame about 143 ms after the last key |
| `<Space>p` (palette) | 0.8 to 1.2 ms | same | |
| `<C-p>` (finder) | 0.7 to 1.6 ms | same | |
| `<Space>` (key hints) | 0.6 ms | 302 ms | the menu at `option.keyhints.delay 300`, deliberate |
| `<Esc>` closing any float | 50.7 to 51.2 ms | same | the escape-sequence wait |
| start, no file | 6.5 to 10 ms | 632 ms | the start screen animates for about 0.6 s |
| start, a file | 7 to 10 ms | 8 ms | 260 to 520 ms when the language server starts |

Every local answer is far under the 50 ms a user notices, Escape and the hint delay by design. Hover and completion with a real server add the server's time; they are re-measured with `ruby-lsp` in `ux-pass-2`.

### Findings kept

Each kept finding is appended to `docs/backlog.md` with this reproduction.

1. First-use hints wait for the logo animation. Facet: the start screen is carat's own and calm, but for about 0.6 s the first screen shows a single dot and no hint (`start-early`: rows 16 to 18 empty; `start-late`, `first-start`: the logo, the name, and the three hints). Others: Neovim's intro and VS Code's welcome show their text in the first frame. Skeptic: agrees, since the hints are the one thing a first-time user needs and nothing is gained by holding them. Reproduction: start `carat` with no file, read the screen within 100 ms (`start-early`). Location: `carat/domain/start_art.rb:67` (the hints), `carat/adapters/input_controller.rb:150` (the animation).
2. The Ctrl-C hint tells a user with nothing to lose to abandon all changes, and spells the name `Carat`. Facet: the line is Neovim's sentence with the name swapped and capitalized, where carat writes `carat` everywhere else (the start screen, the usage line); on a pristine `[No Name]` buffer `:q` is the whole answer, and the start screen vanishes. Others: Neovim prints the same sentence with `:qa!`. Skeptic: agrees on the wording when nothing is modified and on the name; the start screen vanishing on a message is minor and folded in. Reproduction: start with no file, `<C-c>` (`first-quit-hint`). Location: `carat/use_cases/actions/message_handler.rb:10`.
3. The language server's status segment punches a hole in the status bar. Facet: the bar is one band of `#2e3346`, but `fakelsp starting` (yellow) and `fake-lsp` (green) are drawn on the terminal's default background, columns 40 to 57 and 48 to 57 of row 23. Others: both draw a server's state inside their status bar's band. Skeptic: agrees, the color runs show it. Reproduction: a user `caratrc` naming a language server and trusting the project, start on `greet.rb` (`lsp-starting`, `lsp-ready`, row 23's colors). Location: `carat/domain/themes.rb:129` to `:131` (`STATUS_LSP_*` with background `NONE`); `carat/adapters/status_bar.rb:316` reuses `STATUS_LSP_READY` for finished progress.
4. The explorer's help is one message line cut at the terminal's width. Facet: `?` prints every key on row 24 and loses the end at 80 columns (`empty-explorer-help`: `... a add  r rename  d delet`), so `R`, `H`, `-`, `C`, and `q` are never shown. Others: Neovim's file trees open their help in a window; carat's own key-hint menu is a bordered float. Skeptic: agrees, the screen shows the cut. Reproduction: in the empty folder `<Space>e`, then `?` (`empty-explorer-help`). Location: `carat/plugins/explorer/plugin.rb:16` and `:249`.
5. Enter on a finder with no match closes it silently and drops the query. Facet: the finder says `No match` (`empty-finder-nomatch`), then `<CR>` closes it with no message (`empty-finder-nomatch-enter`), so a typo costs the whole query. Others: VS Code's quick open and Neovim's fuzzy finders stay open on Enter with no match. Skeptic: agrees. Reproduction: start with no file in the project, `<C-p>`, `zzqx`, `<CR>`. Location: `carat/plugins/finder/plugin.rb`, the open action with no entry.
6. Insert mode is shown twice. Facet: the status bar's `INSERT` pill and `-- INSERT --` on the message row say the same thing (`time-insert-char`, `float-completion-lsp`: rows 23 and 24), which is noise beside a mode pill and takes the message row while typing. Others: Neovim shows only `-- INSERT --` by default, and users with a status line turn it off (`noshowmode`); VS Code's Vim modes show the mode once. Skeptic: agrees. Reproduction: start on `notes.txt`, `i` (`time-insert-char`). Location: `carat/adapters/frame_presenter.rb:1255`.
7. The key-hint menu mixes three ways of naming an entry. Facet: under `<Space>` the entries read `Open the file tree, focus it, or close it when it is focused` (a sentence), `files`, `windows` (lower-case group names), and `Command palette` (title case), in an order that is neither alphabetical nor the configuration's (`msg-leader-menu`). Others: VS Code's menus and Neovim's which-key style menus use short labels of one style. Skeptic: agrees, readability is goal 1's word. Reproduction: start on `notes.txt`, `<Space>`, wait one second (`msg-leader-menu`). Location: `config/default.caratrc:200` to `:205` (the group names), the action descriptions shown for single keys (the explorer's toggle in `carat/plugins/explorer/plugin.rb`), `carat/domain/key_hints.rb`.
8. The completion popup is the only float without a border. Facet: hover, the finder, the palette, and the key-hint menu share one look, a rounded border in `#6c7286` with a bold `#7fa6ff` title on `#15171e`; the completion popup is the same background with no border or title (`float-completion-lsp`, `float-completion-keyword` against `float-hover`, `float-palette`). Others: Neovim's popup menu has no border, VS Code's suggestion widget has one. Skeptic: agrees only that the rule is unwritten: a borderless inline list near the cursor is defensible, so the fix is to decide and record it, not necessarily to add a border. Reproduction: start on `greet.rb`, `8G`, `o`, `gre` (`float-completion-lsp`). Location: `carat/adapters/frame_presenter.rb:661` (borders only for an edged float).
9. The palette and the finder frame their prompt and title differently. Facet: the finder's prompt is `> ` and its title counts (`Files 0/5`, `empty-finder-nomatch`), the palette's prompt is `>` with no space (`>wri`) and its title `Commands` has no count (`float-palette-filter`). Others: VS Code's command palette and quick open share one widget. Skeptic: agrees, the two are the same kind of float a few keys apart. Reproduction: start on `greet.rb`, `<Space>p`, `wri` (`float-palette-filter`), then `<Esc>`, `<C-p>`, `zzqx` (as `empty-finder-nomatch`). Location: `carat/adapters/frame_presenter.rb:107`, `carat/use_cases/discovery/follow_palette.rb:36`, `carat/plugins/finder/plugin.rb:22`.
10. The palette leads with internal action names and cuts descriptions mid-word. Facet: each row starts with a 30-column dotted name (`motion.repeat_find`, `plugin.explorer.toggle_hidden`) and the description is cut with no ellipsis (`Replace the word with completio`, `Show or hide entries whose name`) while the key column beside it is empty (`float-palette-filter`, rows 15 to 17); the unfiltered list opens on `motion.repeat_find` and the arrow motions (`float-palette`). Others: VS Code's palette shows a readable label first and the key binding at the right. Skeptic: agrees on the cut text and on the order; the dotted names stay useful to configure keys, so the fix keeps them, dimmed and second. Reproduction: start on `greet.rb`, `<Space>p` (`float-palette`), `wri` (`float-palette-filter`). Location: `carat/use_cases/discovery/follow_palette.rb:34` and `:163`.
11. The buffer list is Vim's `:ls` line. Facet: `<Space>bb` prints `1 %a   "greet.rb"   line 3` on the message row (`float-buffers`), Vim's format, where carat's finder and palette offer a list to pick from; the buffer list is the first item of the user's UI order in `docs/goals.md`. Others: Neovim's `:ls` prints the same; its fuzzy finders and VS Code's open-editors list let a user pick. Skeptic: agrees with the leader binding getting a picker, and wants `:ls` itself to keep Vim's output, since `docs/actions.md:168` documents `buffer.list` as "as `:ls` does", so this is a behavior change for planning to decide. Reproduction: start on `greet.rb`, `<Space>bb` (`float-buffers`). Location: the `buffer.list` action, `docs/actions.md:168`.

### Findings the skeptic dropped

- The explorer on an empty folder shows only its root line (`empty-explorer`: `▾ empty` and nothing below). VS Code shows an empty folder as an empty tree too, and Neovim's file trees show the root only; calm, and the add key is one `?` away once finding 4 makes the help readable; dropped.
- A failed motion and an unbound key are silent (`fail-up-at-top`, `fail-unbound-key`: the screen does not change). Neovim's default `belloff=all` is just as silent, and silence is calm; dropped.
- An error message stays until the next key (`fail-ex-unknown-later`, `fail-ex-next-key`). Errors are red and bold on row 24, information in the default color, all on one row: consistent, as Neovim; dropped.
- `q` does not close the hover float (`float-hover-q`); `<Esc>` does (`float-hover-esc`). Neovim's hover closes on `q` only once focused; dropped.
- `<Esc>` closes a float after about 51 ms, the escape-sequence wait. Neovim's `ttimeoutlen` default is the same 50 ms; dropped.
- `<Esc>` in the completion popup closes it and stays in insert mode (`float-completion-esc`). That is VS Code's behavior and the documented `completion.close` binding; dropped.
- The finder float keeps its full height with 13 empty rows for five files (`empty-finder-open`). Neovim's fuzzy finders also keep a fixed size, and a stable box is calm; dropped.
- The status segment names the server's command while starting (`fakelsp starting`) and the server's own name once ready (`fake-lsp`). Informative, not confusing; dropped.
- Hover in about 41 ms and completion in about 143 ms with a server that answers at once. Under the threshold for hover; completion is close to noticeable but a canned server is no evidence, so it is re-measured with `ruby-lsp` in `ux-pass-2`; dropped here.

### What held up

Messages sit on one row with one error color, the E-numbered texts match the ex commands users know, the bordered floats share one palette and padding, `<Esc>` closes every float, and every local key answers in about a millisecond.

## Risks / Trade-offs

- The canned server makes hover and completion timings carat's side only; the real figures come with `ruby-lsp`.
- The terminal model renders what carat draws for a 24x80 terminal with the escapes carat uses; a wide glyph would shift a row by one column, and none appears in these screens.
- The skeptic is the reviewer's own adversarial pass, not a separate agent; the dropped list records each argument so planning can overrule it.
