# carat

A terminal IDE written in Ruby with Neovim's modal editing model, built, tested, and shipped with Spinel. `docs/architecture.md` holds the design and the roadmap; `docs/codebase-map.md` places every source file in its area; `CLAUDE.md` holds the commands and conventions.

Today it is an editor with split windows, tab pages, a plugin host, and a file tree: normal, insert, operator-pending, command-line, and the charwise, linewise, and blockwise visual modes (`v V <C-v>`, `o O gv`, every motion and text object, and `d x y c s > < J gJ p P r ~ u U X D C S R Y I A` on the selection); counts, the `"x` register prefix, and Neovim's `[count] operator [count] motion` grammar; the motions `h l 0 ^ $ f F t T ; , j k G gg + - _ w W b B e E ge gE ( ) { } H M L`; search with `/ ? n N * # g* g#`, also under an operator and in the visual modes; substitute with `:s`, `:&`, `&`, `g&`, and the ranges `% . $ N '<,'>`; the global commands `:g`, `:g!`, and `:v`, and `:d`; the text objects `iw aw iW aW is as ip ap` and the bracket and quote objects; the operators `d c y > <` with `dd cc yy >> <<` and `x s S C D Y J p P r ~`; undo and redo with branches (`u`, `<C-r>`, `U`, `g-`, `g+`, `:undo`, `:redo`, `:undolist`, `:earlier`, `:later`) and the dot command `.`; the unnamed, named, numbered, small delete, black hole, and read-only registers with `:registers`; insert-mode editing; the window commands `<C-w>s v h j k l w W p c o = q`, also with Ctrl held on `s v h j k l w p o q`, which wait for their second key however long it takes, `gt`, and `gT`; scrolling with `<C-f> <C-b> <PageDown> <PageUp> <C-d> <C-u> <C-e> <C-y> zt zz zb` and the `scroll` option; and the ex commands `:w :q :wq :x :wa :qa :wqa :xa :e :sp :vs :new :vnew :close :only`, the buffer list commands `:ls :buffers :files :bnext :bprevious :bNext :buffer N :bdelete`, and `:tabnew :tabedit :tabclose :tabonly :tabnext :tabprevious :tabfirst :tablast`. Ruby files are highlighted in color, and `:syntax on`, `:syntax off`, `:set filetype=`, and `:set syntax=` switch it. `:e` refuses a directory, a FIFO, a device, or a file over 64 MiB with Vim's message and keeps the current buffer. A file that is not valid UTF-8 opens with its bytes kept and written back as they were, `[ILLEGAL BYTE in line N]` naming its first such line and each illegal byte drawn as one U+FFFD cell. Compiled plugins add actions, ex commands, side windows, and tokenizers through the API in `docs/plugins.md`; the built-in `explorer` plugin, the file tree below, and the built-in `ruby` plugin, the Ruby tokenizer, are built on it. `docs/compatibility.md` lists every Neovim command it implements with its test, and `docs/backlog.md` the known items left for later changes.

## Building

The prerequisites are a C compiler, `make`, `git`, and `curl`. No Ruby interpreter is needed, not even to build the compiler, and none is ever used: every `make` target puts `tools/noruby` first on its `PATH`, whose `ruby` refuses to run, so a CRuby installed on the machine is never reached.

1. `make toolchain` fetches the pinned Spinel commit into `tmp/.spinel`, builds it, and installs `spinel`, `spin`, and `spinel-doctor` under `tmp/.toolchain`. Both directories are ignored by git, every `make` target finds the toolchain there on its own, and `make toolchain-clean` removes them.
2. `make build` compiles the editor to `build/bin/carat` and prints the alias line to add to your shell profile to run it from anywhere; `make install` puts it on the `PATH` instead.
3. `make check` runs the canonical stage list: the toolchain check, the documents' size and quality, the release and development builds, the generated config's freshness, every test against its snapshot, `spinel-doctor`, the `make no-cruby` proof, the allocation budget, the tests of the shell tools, and the rule gates; run it before every push. `make test-one T=test/NAME.rb` compiles and runs one test on its own. Run tests, snapshots, and benchmarks only through `make`, never with `spin test` directly: for a test program without a snapshot, `spin test` compares against the `ruby` on your `PATH`.

| Command | What it does |
| --- | --- |
| `make doctor` | Check that `spinel`, `spin`, a C compiler, and `node` are on the path, and that the `ruby` every target reaches is the refusing stub |
| `make no-cruby` | Prove that a test program without a snapshot fails instead of being compared against a CRuby |
| `make toolchain` | Fetch, build without Ruby, and install the pinned Spinel commit under `tmp/` |
| `make toolchain-clean` | Remove `tmp/`, the Spinel checkout and the installed toolchain |
| `make build` | Compile `bin/*.rb` into `build/bin` and print how to run it from anywhere |
| `make dev-build` | Compile the editor with the development flags into `build/dev/carat`, the binary CI's smoke test runs on pull requests, and check its analysis budget |
| `make run FILE=path` | Build and run the editor on a file |
| `make test` | Build, compile every test into the one test runner, then run each test against its snapshot |
| `make test-build`, `make test-run` | The two halves of the test step: compile the runner, run the tests from it |
| `make test-one T=test/NAME.rb` | Compile one test program on its own and run it against its snapshot |
| `make lint` | Run the lint test program only |
| `make types` | Print the signatures Spinel inferred |
| `make diagnose` | Run `spinel-doctor` on every compile root: `bin/*.rb` and the test runner |
| `make diagnose-one T=path` | Run `spinel-doctor` on one file |
| `make bench` | Build and run the key benchmark: time, bytes written, collector share, and allocations per key |
| `make bench-budget` | Build the benchmark with the development flags and fail when a key of the cursor scenario allocates 100 objects or more; CI runs it |
| `make analysis-budget` | Fail when Spinel's analysis of `bin/carat.rb` or the test runner needs more than 2 re-narrowing rounds, a sign that a value widened to `untyped`; `make dev-build` and `make test-build` check their own reports on every build |
| `make profile` | Build the benchmark with `spinel --profile` and print the top functions with `perf` when it works |
| `make snapshots` | Rebuild the test runner and rewrite every test's snapshot from it |
| `make gen-config` | Regenerate the default config mirror and the plugin registry |
| `make config-current` | Fail when `make gen-config` rewrote the config mirror or the plugin registry |
| `make docs-lint` | Check the documents agents read: byte budgets (`CLAUDE.md` 30 KiB, each agent file 8 KiB, `docs/architecture.md`, `docs/queue.md`), no link, address, session id, or model name, no hard-wrapped pull request text, no backticked path that does not exist, every item of `docs/queue.md` tagged with a tier and a size |
| `make tools-test` | Test the shell tools behind CI and the delivery pipeline in temporary repositories |
| `make gates` | Check the branch against the rules: the commit trailer, no link, address, or session id, snapshots from the runner, the docs kept current, and the attribution settings |
| `make check` | Run every stage of `make stages` in order; `make check-stage S=NAME` runs one |
| `make new-use-case`, `make new-action`, `make new-ex-command`, `make new-test`, `make new-plugin` | Scaffold one file of that kind from its golden example and wire it in: signatures, the code map, requires and registrations, the documentation row, the runner lines, and a snapshot; `docs/examples.md` lists the arguments |
| `make spec-list`, `make spec-validate`, `make spec-update` | The OpenSpec commands; `spec-validate` also validates each active change as its archive would leave the specs |

## Starting

`carat FILE` opens a file, or starts a new one when nothing is there. `carat` with no argument, or with a directory, starts on an empty buffer and shows the start screen: a gem forms from a point in about 0.6 seconds, a sparkle lights its top, and `c a r a t` appears with the keys to insert text, open a file, and quit. Any key ends it and does what it always does. `option.startscreen false` turns it off, `option.reducedmotion true` shows the finished picture without the animation, a terminal too small for the gem shows only the wordmark, and with the `NO_COLOR` environment variable set the picture is drawn in plain ASCII without colors of its own.

The cursor is a block in normal mode, a bar in insert mode, and an underline in replace mode, and the current window highlights the cursor's line (`option.cursorline false` or `:set nocul` turns it off). However carat ends, `:q`, a signal, or an error, the terminal gets its own cursor shape and its main screen back.

## Leader keys

The leader is Space. Its keys come in groups named by their first letter, and each group key waits for the next key however long it takes; Escape cancels it.

- `<leader>w` windows: `ws` split, `wv` split vertically, `wh` `wj` `wk` `wl` go to the window left, below, above, or right, `wc` close, `wo` keep only this one; a count works as with `<C-w>`.
- `<leader>q` quit: `qq` quits as `:qa` does, `qw` writes every changed buffer and quits as `:wqa` does.
- `<leader>f` files: `fs` saves as `:w` does; `ff` will open the finder and says "Not implemented" until it arrives.
- `<leader>b` buffers: `bb` lists them as `:ls` does, `bn` and `bp` go to the next and previous one, `bd` deletes this one, or with a count the buffer of that number.
- `<leader>e` opens the file tree, as before.

Ctrl-S saves in normal and in insert mode, where you stay in insert mode. Carat runs the terminal in raw mode, so flow control is off and Ctrl-S reaches it instead of freezing the screen.

These keys moved: `<leader>w` used to write the file and `<leader>q` to quit the window. Press `<leader>fs` or Ctrl-S to write, and `:q` or `<C-w>q` to close a window, or `<leader>qq` to quit. To get the old keys back, add `keymap.normal <leader>w :w<CR>` and `keymap.normal <leader>q :q<CR>` to `~/.config/carat/caratrc`. Every action has a short description in the editor, which the coming key hints will show.

## Configuration

Carat reads its settings from plain text files of one setting per line, `scope.name value`: the first word is a dotted key, and the rest of the line is the value, a word, a number, `true` or `false`, or a list of words separated by spaces. A word containing spaces goes in double quotes (`\"` and `\\` inside them stand for a quote and a backslash), `#` starts a comment, and blank lines are ignored.

```
# ~/.config/carat/caratrc
option.number true
option.tabstop 2
option.theme one_dark
keymap.normal <leader>e plugin.explorer.toggle
keymap.normal <leader>w :w<CR>
keymap.normal Q none
plugin.explorer.enabled true
plugin.explorer.width 30
plugin.explorer.ignore .git build tmp
```

- `option.<name>` sets an option by its Vim name (`number`, `relativenumber`, `tabstop`, `shiftwidth`, `expandtab`, `autoindent`, `scroll`, `scrolloff`, `timeoutlen`, `undolevels`, `cursorline`, and the others), plus Carat's `icons`, `theme`, `background`, `startscreen`, and `reducedmotion`; `tabstop` takes 1 to 9999 and `shiftwidth` 0 to 9999, as in Vim.
- `keymap.<mode> <keys> <action>` binds keys in Vim notation in `normal`, `insert`, `visual`, `visual_line`, `visual_block`, `operator_pending`, or `cmdline` mode to an action from `docs/actions.md` or to keys to replay, such as `:w<CR>`; the action `none` removes a binding. `keymap.leader <Space>` sets what `<leader>` stands for.
- `plugin.<name>.enabled` turns a plugin on or off, and `plugin.<name>.<option>` sets one of its options.
- `language.<name>.lsp` and `language.<name>.formatter` name the commands the language services will run; they are read from the defaults and the user file only, never from a project's file, so opening a directory cannot choose a program to run. For the same reason a project's file may bind keys only to actions and `none`, not to keys to replay.

The files load in order, and a later line wins: the built-in defaults (`config/default.caratrc`, every option and binding Carat ships, built into the binary), then `~/.config/carat/caratrc`, then `.caratrc` in the directory Carat starts in. Every line is checked when the files load; a mistake is reported as `file:line: message`, that line is skipped and the rest still applies, and the first problem shows in the message row when Carat starts, with the number of the others. A line holding a byte that is not UTF-8 is such a mistake. A configuration file that is not a regular file (a FIFO, a device) or holds more than 1 MiB, and a project's `.caratrc` that is a symbolic link, is reported and not read, so a cloned repository cannot hang or exhaust Carat at startup.

## Search

`/pattern<CR>` searches forward and `?pattern<CR>` backward, `n` and `N` repeat the last search in the same or the other direction, and `*`, `#`, `g*`, and `g#` search for the word under the cursor. Each takes a count, works after an operator (`d/foo<CR>`, `cn`) and in the visual modes, wraps around the buffer with Vim's "search hit BOTTOM, continuing at TOP", and the last pattern is in the `/` register. `<Up>` and `<Down>` at the `/` or `:` prompt recall earlier patterns or commands starting with what you typed.

- Patterns are Vim's magic patterns: `. * \+ \= \{n,m} ^ $ [a-z] \( \) \| \< \> \s \d \w \k \c \C \v \V` and the rest `docs/compatibility.md` lists; back references and look-around are not supported.
- `hlsearch` (on) highlights every match until `:noh`, `incsearch` (on) moves to the first match while you type, and `ignorecase` with `smartcase` ignores case unless the pattern has a capital letter; set them with `option.hlsearch false` in a configuration file or `:set nohls`, `:set ic`, `:set scs?`.
- A pattern can never hang Carat: one too large is refused with `E363`, and a search that would scan too long stops with a message.

## Substitute

`:s/pattern/string/` replaces the first match on the cursor line, and `g` after it every match: `:%s/old/new/g` changes every line, `:2,5s/a/b/` lines 2 to 5, and `:` in a visual mode starts the command line with `'<,'>`, the selected lines. A range alone moves the cursor (`:12`, `:$`). The string takes `&` for the match, `\1` to `\9` for the pattern's `\(\)` groups, `~` for the last string, `\u \U \l \L \e` for case, and `\r` for a line break.

- The flags `& e g i I n r p #` work as in Vim: `:%s/x//gn` counts the matches, `e` keeps quiet when there is none, and `&&` reuses the last flags.
- `:&`, `:s` alone, and `&` repeat the last substitute on the range or the cursor line, `3&` on three lines, and `g&` on every line with the last search pattern and flags.
- A substitute is one undo step, its pattern becomes the last search for `n`, and like a search it can never hang Carat: one that would work too long changes nothing and reports `E363`.

## Global

`:g/pattern/command` runs an ex command on every line that matches: `:g/TODO/d` deletes those lines, `:g/^#/s/x/y/` substitutes on the comment lines, and `:g/x` alone lists them. `:v/pattern/command` and `:g!` run on the lines that do not match. A range limits the lines (`:10,20g/x/d`); without one every line counts.

- A line is visited only if it matched before the command ran on any line, so lines a command deletes or inserts are never visited by mistake.
- `:[range]d [x] [count]` deletes lines into a register, the numbered registers shifting as with `dd`.
- A global is one undo step, its pattern becomes the last search for `n`, and like a search it can never hang Carat.

## Syntax highlighting

Carat highlights the files whose filetype a plugin tokenizes; the built-in `ruby` plugin covers Ruby: `.rb`, `.rake`, `.gemspec`, and `.ru` files, `Gemfile`, `Rakefile`, `config.ru`, and any file whose first line is a `ruby` shebang. Comments and their `TODO`s, keywords, definitions, constants, variables, symbols, numbers, strings with escapes and nested interpolation, percent literals, heredocs, and regular expressions get Neovim's standard highlight groups, and a construct that spans lines keeps its color on the lines that follow. Only the rows on the screen and the rows above them are ever tokenized, so a large file opens as fast as a plain one, and an edit re-highlights only until the colors after it are the same as before.

- `:syntax off` draws every buffer plain and `:syntax on` brings the colors back.
- `:set filetype=ruby` (or `:set ft=ruby`) highlights the current buffer as Ruby, `:set syntax=OFF` turns one buffer plain, and `:set ft?` shows the filetype.

The colors come from a palette, chosen by the `option.theme` line of the configuration: `one_dark`, the default, or `dark_plus` (Visual Studio Code's Dark+) for a dark terminal, and `one_light` or `light_plus` for a light one; `carat-dark` and `carat-light` still work and name the One palettes. Each palette has its own syntax colors and colors the status bar and its mode pill, the buffer tabs, the line numbers, the selection, the search matches, the messages, and the file tree's icons as well, and every text color in it is readable on its background at WCAG AA contrast. The terminal keeps its own background unless `option.background theme` asks the palette to paint it, which needs a terminal that clears with the current background color, as most do.

```
option.theme light_plus
option.background theme
```

Carat writes 24-bit colors when the terminal sets `COLORTERM` to `truecolor` or `24bit` (most modern terminals do), the 256-color palette otherwise, and the 16 basic colors when `TERM` names a terminal that has only those, such as the Linux console (`linux`). To turn the Ruby highlighting off, add the line `plugin.ruby.enabled false`.

## File tree

`<leader>e` (Space, then `e`) or `:Explorer` opens a file tree in a 30-column window at the left, rooted at the directory you started Carat in, with the current file revealed and marked; the same key focuses the tree when it is open and closes it when it is focused. `:ExplorerFind` reveals the current file in the tree. Inside the tree:

- `<CR>` or `l` opens a file in the window you came from; on a directory `<CR>` and `o` toggle it, `l` expands it, and `h` collapses it or goes to the parent.
- `s`, `v`, and `t` open the file in a horizontal split, a vertical split, or a new tab page.
- `a` creates a file next to the entry, or a directory when the name ends with `/`; `r` renames; `d` deletes a file or an empty directory after asking `y` or `n`. The name is typed on the command line, Enter confirms, Escape cancels.
- `R` refreshes, `H` shows dot files, `-` moves the root up, `C` makes the directory under the cursor the root, `q` closes the tree, and `?` shows these keys.
- `j`, `k`, `gg`, `G`, and the `<C-w>` commands work as in any window; `:q` in the last file window quits even while the tree is open.

The tree draws its folders and file types with the icons below, so it reads well with or without a Nerd Font. Its options live in your configuration:

```
plugin.explorer.width 30
plugin.explorer.side left
plugin.explorer.show_hidden false
plugin.explorer.ignore .git build tmp
```

`side` is `left` or `right`, `show_hidden` lists names starting with a dot from the start, and `ignore` names entries the tree never lists. Add `plugin.explorer.enabled false` to turn the tree off, and bind `<leader>e` to something else, or to `none`, to free the key.

## Icons and Nerd Fonts

The file explorer, the diagnostics, and the plugins draw small icons: folders, file types, error and warning markers. By default they come from a Nerd Font, a font family that adds thousands of such glyphs to a programming font. The font is optional: the editor is fully usable without one, see the `icons` option below.

To use the icons, install a Nerd Font and select it in your terminal. JetBrainsMono Nerd Font is a good choice.

- macOS: `brew install --cask font-jetbrains-mono-nerd-font`, then pick "JetBrainsMono Nerd Font" in the terminal's profile settings.
- Arch Linux: `pacman -S ttf-jetbrains-mono-nerd`.
- Other Linux distributions: download the `JetBrainsMono` archive from the Nerd Fonts project's releases, unpack it into `~/.local/share/fonts/`, and run `fc-cache -f`.
- Windows: install the font on the Windows side (unpack the same archive and select the font files, then "Install") and choose it in Windows Terminal's profile, so a terminal running Carat under WSL draws with it.

Then select the font in the terminal: in iTerm2, Terminal.app, Windows Terminal, GNOME Terminal, Konsole, Alacritty, WezTerm, kitty, and the others, the font is a setting of the profile or the configuration file; the terminal, not Carat, draws the glyphs.

Without a Nerd Font the icon cells show boxes or blanks. Set the `icons` option in your configuration to another set instead:

```
option.icons unicode
```

`unicode` uses triangles, bullets, and geometric shapes that common terminal fonts already have, and `ascii` uses plain characters such as `+`, `-`, `*`, and `!`. The default is `nerd`. Plugins ask for icons by name, so the option switches every icon in the editor.

## How carat is built with AI

Every change to carat, from a feature to a one-line fix, is written by Claude agents and goes through the same pipeline; a person decides what to build and reads the result. The pipeline is a workflow, `.claude/workflows/deliver-change.js`, whose phases are fixed in code, so no step depends on an agent remembering it. The mechanical agents, the scouts, the checker, the benchmark, and the merger, run on the cheapest tier, named by the `model:` line of their frontmatter; the others run on the session's model.

1. The planner orders the queue. Before a change starts, it reads the metrics history, the findings and proposals earlier runs left, the backlog, and the goals, and writes the next `docs/queue.md` by the rubric of `docs/goals.md`: each item tagged with a tier, T0 (a blocking security finding, a red `main`, a crash) to T6 (advisories), and a size, small, medium, or large, a budget of total tokens, input plus output (and 25 minutes for a small change); each decision citing its tier and a number: a metric, a finding, or the user's request. A brief with more than about four separate fixes is split into balanced changes. The planner runs only when the queue needs a decision: a change other than the queue's head, a request beyond a change name, or a proposal or finding an earlier run left; otherwise the next item is taken as written. A planned queue fits the byte budget of `docs/queue.md`, the planner reading the backlog by its headings. When a blocking security finding is still open, the run stops so its fix goes first.
2. Scouts read the code. For each area of `docs/codebase-map.md` whose files the change edits, at most three, a read-only scout writes a context pack of facts about the existing code the change edits or hooks into (files, methods, callers, tests, designs, the map's rules line) to `tmp/scout/`, and a pack still current at `main` is reused; when the brief is only the change name, the scouts and the contributor read its item in `docs/queue.md` themselves. Findings the change only records in the backlog reach the contributor as the planner's notes, not through a scout.
3. The contributor implements. It keeps the brief it was given and plans the change with OpenSpec (the brief, a proposal, a design, and tasks under `openspec/changes/`, archived together), starts each new file from its golden example in `docs/examples.md` or the `make new-*` generator that wires it in, reads the Spinel pitfalls once in `docs/spinel-notes.md`, writes the code and its tests, and commits as it goes. It is the only agent that edits the repository.
4. The checker runs `make check` stage by stage, each with its log, and never edits. A stage it recorded counts only at the last check recorded in the run state, so a commit already checked is not checked again and a stage recorded at any other commit runs again. After a fix that changes only tests, it reruns only the test stages, the docs lint, and the gates and carries the others. The editor's development build, the test runner's build, and `spinel-doctor` are skipped when the code they read is the code of their last pass with the outputs it left, so a change to tooling or documents does not compile again what `main` passed; CI still compiles on any path but documentation. It refuses a tree with uncommitted changes. After a pass it notes the output tokens spent so far against the budget of the change's size, a sixth of its total-token budget, and the workflow records an overrun for the planner without stopping the run.
5. The quality reviewer reviews the committed diff for bugs and for the project's rules: idiomatic Ruby within Spinel's rules, naming, one public `call` per use case, the layers, and simple code, beside the security reviewer on the same commit, so one fix round answers both. After a fix that changed only the files the blocking findings name, tests, and the records, it reviews only the fix and those findings. Each advisory finding is kept once as a note in the run state and goes into `docs/backlog.md` with the change, so none is lost.
6. The security reviewer reviews the whole committed diff for vulnerabilities in every round. It is the most important gate: it can never be skipped, and a High or Medium finding it is confident in blocks the merge until it is fixed.
7. The benchmark: the check's `metrics` stage measures allocations and time per key and Spinel's analysis rounds, and `make metrics-compare` compares them with the figures recorded for `main`: those of the newest merged change without a row in `docs/metrics.tsv`, else its last row. When allocations and rounds are equal nothing more runs; otherwise the benchmark agent measures `main` itself: more allocations or rounds block, slower time is reported.
8. Whatever blocks goes back to the contributor, and every later phase runs again on the new commit, at most three rounds before the run stops and asks, a red CI included. The rounds are counted across restarts; a restart after a stop the limit did not cause (a killed stage, a restarted container) gets one more, recorded with its reason. A check that did not finish, killed or superseded by a newer commit, costs no round: it runs detached from the checker, which rejoins it at the same commit, and the workflow starts it again, at most twice in a row, naming the stage and its log.
9. The contributor archives the OpenSpec change, commits the planner's queue and the history rows of the changes merged before it, pushes once, and opens the pull request from the template. The merger waits for CI, which compares the pull request's measurements with the last push to `main`, without giving up while a check still runs: one merger start waits up to 30 minutes, in the foreground through `tools/ci_wait.sh`, 3, 4, then 5 minutes at a time; a red run goes back to the contributor with its log. A merge whose CI passes within two waits takes at most 10 tool calls: the workflow hands the merger its records and the merge gates as one command. On green the merger runs the merge gates of a fresh worktree of `main`, which the branch cannot have edited, and squash-merges the head they checked with the body the contributor wrote.
10. The retrospective closes the run in one start: it runs the run's last records, flags a run over its size budget with a line starting `under:` or `over:` (the run state keeps the size the planner estimated, so the history row carries it beside the total and output tokens after the queue item is gone), and proposes at most three ways to simplify the workflow, its script, or its agents, each backed by numbers, and writes the report in a fixed shape that names any rule broken. Every five merged changes, and after any change to config loading, file access, plugin boundaries, terminal output, process spawning, the entry point, or the agent guard and the gates, a periodic review of the whole codebase follows (other tooling, documentation, and a change to `config/default.caratrc` that edits only key bindings count only toward the five): a security review, never skipped, and a quality review. What they find goes to the planner, so a later change acts on it. A review that reaches its cap returns what it covered and names what it did not, recorded as `partial`, and a security review that returns nothing is started once more and then recorded as `not-run`, never as passed; either keeps the next periodic review due.

Rules are checked, not remembered. `tools/gates.sh` refuses a commit without its single co-author trailer, a link, an email address, a session id, or a model name in the diff, the commits, or the pull request; a snapshot not written by the test runner; a new file missing from the code map; a new command, binding, option, make target, or process change without this README; a second push without a CI failure to fix; and a merge without the recorded passes of the check, the quality and security reviews, and the benchmark at the pushed head.

Documents are budgeted too. `make docs-lint`, a stage of `make check`, keeps `CLAUDE.md` within 30 KiB, each agent file within 8 KiB, `docs/architecture.md` within its budget, and `docs/queue.md` within 17,369 bytes, because agents read them on every run, and refuses a link, an address, a model name, hard-wrapped pull request text, or a path that no longer exists. When `authoring-kit` introduced it, `CLAUDE.md` went from 41,066 to about 30,600 bytes and `docs/architecture.md` from 91,890 to about 87,300, the detail moving to `docs/spinel-notes.md` and `docs/examples.md`.

The run state of a change, `build/pipeline/<change>.json`, records each phase and the commit it finished at, every check stage, the reviews, the pushes, the pull request, and CI. It is written only by `tools/run_state.sh`, which refuses a control character in any key or value, so an interrupted run picks up where it stopped, trusting only the records at a commit of the branch or of `main`. The phases and the reviews are recorded by the workflow from what each agent returned, never by the agents, and the merger compares them with what the workflow received before it merges. Every agent runs `main`'s `tools/agent_guard.sh` before each shell command or file write, and a guard that is missing or fails refuses the call. Each agent may run only the commands its role needs, read as the shell reads them: the agents that never edit cannot commit, push, call `gh`, write the run state's records, or write a file outside their own directory, and the contributor pushes only through `tools/run_state.sh push`, which runs the gates first. Until that push, `tools/run_state.sh backup` keeps the branch's commits on origin under `refs/backup/`, which opens no pull request and starts no CI run, so a resume after a reclaimed container restores them; it runs the trailer and content gates, which refuse keys, platform tokens, literal passwords, and `.env` files in any commit, from the commit of `main` the branch forked from, which it pushes beside them so a restore takes only commits descended from it. The push and the merge delete the backup; to give up a stopped run, run `sh tools/run_state.sh abandon <change>`, which deletes it.

Every run is measured. `/deliver` records the total tokens and wall minutes of each start, which only the session that ran the workflow sees, with `tools/run_state.sh usage`; the workflow counts the output tokens and tool calls of each phase, whether each gate passed the first time, the rework rounds, and the CI minutes, and stores them in the run state: each metric line holds every figure, run by the workflow's record step after the reviews and at the end and by the merger and the retrospective before their work, so a resumed run keeps them and the run state's totals equal the ones the retrospective is given; the check adds allocations and time per key and the analysis rounds. Each agent start is told its cap of tool calls, a figure per kind of start scaled by the size estimate (a fixed one for the periodic review's starts), and a start that reports more is recorded for the planner; each agent file's `maxTurns` is the ceiling the platform enforces. `docs/metrics.tsv` keeps one row per merged change, written only by `tools/run_state.sh`, and `/status` prints the last row and each gate's first-pass rate.

To start or resume a change, run `/deliver` followed by a change name or a short description in Claude Code; `/status` shows the running change and its next phase, `/plan` asks the planner for the next order of the queue with its evidence, and `/review` runs the periodic review now. Outside Claude Code the same checks run with `make check`, `make gates`, `make metrics`, and `sh tools/run_state.sh status`. The plan lives in the repository: `docs/goals.md` is the charter every change serves, token and pipeline efficiency first and security second, `docs/queue.md` the ordered queue with the reason for each place, and `docs/metrics.tsv` the data behind it.
