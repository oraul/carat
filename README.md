# carat

A terminal IDE written in Ruby with Neovim's modal editing model, built, tested, and shipped with Spinel. `docs/architecture.md` holds the design and the roadmap; `docs/codebase-map.md` places every source file in its area; `CLAUDE.md` holds the commands and conventions.

Today it is an editor with split windows, tab pages, a plugin host, and a file tree: normal, insert, operator-pending, command-line, and the charwise, linewise, and blockwise visual modes (`v V <C-v>`, `o O gv`, every motion and text object, and `d x y c s > < J gJ p P r ~ u U X D C S R Y I A` on the selection); counts, the `"x` register prefix, and Neovim's `[count] operator [count] motion` grammar; the motions `h l 0 ^ $ f F t T ; , j k G gg + - _ w W b B e E ge gE ( ) { } H M L`; the text objects `iw aw iW aW is as ip ap` and the bracket and quote objects; the operators `d c y > <` with `dd cc yy >> <<` and `x s S C D Y J p P r ~`; undo and redo with branches (`u`, `<C-r>`, `U`, `g-`, `g+`, `:undo`, `:redo`, `:undolist`, `:earlier`, `:later`) and the dot command `.`; the unnamed, named, numbered, small delete, black hole, and read-only registers with `:registers`; insert-mode editing; the window commands `<C-w>s v h j k l w W p c o = q`, `gt`, and `gT`; and the ex commands `:w :q :wq :x :wa :qa :wqa :xa :e :sp :vs :new :vnew :close :only` and `:tabnew :tabedit :tabclose :tabonly :tabnext :tabprevious :tabfirst :tablast`. Ruby files are highlighted in color, and `:syntax on`, `:syntax off`, `:set filetype=`, and `:set syntax=` switch it. Compiled plugins add actions, ex commands, side windows, and tokenizers through the API in `docs/plugins.md`; the built-in `explorer` plugin, the file tree below, and the built-in `ruby` plugin, the Ruby tokenizer, are built on it. `docs/compatibility.md` lists every Neovim command it implements with its test, and `docs/backlog.md` the known items left for later changes.

## Building

The prerequisites are a C compiler, `make`, `git`, and `curl`. No Ruby interpreter is needed, not even to build the compiler, and none is ever used: every `make` target puts `tools/noruby` first on its `PATH`, whose `ruby` refuses to run, so a CRuby installed on the machine is never reached.

1. `make toolchain` fetches the pinned Spinel commit into `tmp/.spinel`, builds it, and installs `spinel`, `spin`, and `spinel-doctor` under `tmp/.toolchain`. Both directories are ignored by git, every `make` target finds the toolchain there on its own, and `make toolchain-clean` removes them.
2. `make build` compiles the editor to `build/bin/carat` and prints the alias line to add to your shell profile to run it from anywhere; `make install` puts it on the `PATH` instead.
3. `make check` runs the canonical stage list: the toolchain check, the release and development builds, the generated config's freshness, every test against its snapshot, `spinel-doctor`, the `make no-cruby` proof, the allocation budget, the tests of the shell tools, and the rule gates; run it before every push. `make test-one T=test/NAME.rb` compiles and runs one test on its own. Run tests, snapshots, and benchmarks only through `make`, never with `spin test` directly: for a test program without a snapshot, `spin test` compares against the `ruby` on your `PATH`.

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
| `make tools-test` | Test the shell tools behind CI and the delivery pipeline in temporary repositories |
| `make gates` | Check the branch against the rules: the commit trailer, no link, address, or session id, snapshots from the runner, the docs kept current |
| `make check` | Run every stage of `make stages` in order; `make check-stage S=NAME` runs one |
| `make spec-list`, `make spec-validate`, `make spec-update` | The OpenSpec commands |

## Configuration

Carat reads its settings from plain text files of one setting per line, `scope.name value`: the first word is a dotted key, and the rest of the line is the value, a word, a number, `true` or `false`, or a list of words separated by spaces. A word containing spaces goes in double quotes (`\"` and `\\` inside them stand for a quote and a backslash), `#` starts a comment, and blank lines are ignored.

```
# ~/.config/carat/caratrc
option.number true
option.tabstop 2
option.theme carat-dark
keymap.normal <leader>e plugin.explorer.toggle
keymap.insert <C-s> <Esc>:w<CR>
keymap.normal Q none
plugin.explorer.enabled true
plugin.explorer.width 30
plugin.explorer.ignore .git build tmp
```

- `option.<name>` sets an option by its Vim name (`number`, `relativenumber`, `tabstop`, `shiftwidth`, `expandtab`, `autoindent`, `scrolloff`, `timeoutlen`, `undolevels`, and the others), plus Carat's `icons` and `theme`.
- `keymap.<mode> <keys> <action>` binds keys in Vim notation in `normal`, `insert`, `visual`, `visual_line`, `visual_block`, `operator_pending`, or `cmdline` mode to an action from `docs/actions.md` or to keys to replay, such as `:w<CR>`; the action `none` removes a binding. `keymap.leader <Space>` sets what `<leader>` stands for.
- `plugin.<name>.enabled` turns a plugin on or off, and `plugin.<name>.<option>` sets one of its options.
- `language.<name>.lsp` and `language.<name>.formatter` name the commands the language services will run; they are read from the defaults and the user file only, never from a project's file, so opening a directory cannot choose a program to run. For the same reason a project's file may bind keys only to actions and `none`, not to keys to replay.

The files load in order, and a later line wins: the built-in defaults (`config/default.caratrc`, every option and binding Carat ships, built into the binary), then `~/.config/carat/caratrc`, then `.caratrc` in the directory Carat starts in. Every line is checked when the files load; a mistake is reported as `file:line: message`, that line is skipped and the rest still applies, and the first problem shows in the message row when Carat starts, with the number of the others.

## Syntax highlighting

Carat highlights the files whose filetype a plugin tokenizes; the built-in `ruby` plugin covers Ruby: `.rb`, `.rake`, `.gemspec`, and `.ru` files, `Gemfile`, `Rakefile`, `config.ru`, and any file whose first line is a `ruby` shebang. Comments and their `TODO`s, keywords, definitions, constants, variables, symbols, numbers, strings with escapes and nested interpolation, percent literals, heredocs, and regular expressions get Neovim's standard highlight groups, and a construct that spans lines keeps its color on the lines that follow. Only the rows on the screen and the rows above them are ever tokenized, so a large file opens as fast as a plain one, and an edit re-highlights only until the colors after it are the same as before.

- `:syntax off` draws every buffer plain and `:syntax on` brings the colors back.
- `:set filetype=ruby` (or `:set ft=ruby`) highlights the current buffer as Ruby, `:set syntax=OFF` turns one buffer plain, and `:set ft?` shows the filetype.

The colors come from a theme, chosen by the `option.theme` line of the configuration: `carat-dark`, the default, for a dark terminal background, or `carat-light` for a light one. Both leave the background of the text to the terminal and color the status lines, the tab line, the line numbers, the selection, and the messages as well.

```
option.theme carat-light
```

Carat writes 24-bit colors when the terminal sets `COLORTERM` to `truecolor` or `24bit` (most modern terminals do), the 256-color palette otherwise, and the 16 basic colors when `TERM` names a terminal that has only those, such as the Linux console (`linux`). To turn the Ruby highlighting off, add the line `plugin.ruby.enabled false`.

## File tree

`<leader>e` (Space, then `e`) or `:Explorer` opens a file tree in a 30-column window at the left, rooted at the directory you started Carat in, with the current file revealed and marked; the same key focuses the tree when it is open and closes it when it is focused. `:ExplorerFind` reveals the current file in the tree. Inside the tree:

- `<CR>` or `l` opens a file in the window you came from, or expands a directory; `h` collapses or goes to the parent; `o` toggles a directory.
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

Every change to carat, from a feature to a one-line fix, is written by Claude agents and goes through the same pipeline; a person decides what to build and reads the result. The pipeline is a workflow, `.claude/workflows/deliver-change.js`, whose phases are fixed in code, so no step depends on an agent remembering it.

1. Scouts read the code. For each area of `docs/codebase-map.md` the change touches, a read-only scout writes a context pack of facts (files, methods, callers, tests, designs, rules) to `tmp/scout/`, and a pack still current at `main` is reused.
2. The contributor implements. It plans the change with OpenSpec (a proposal, a design, and tasks under `openspec/changes/`), writes the code and its tests, and commits as it goes. It is the only agent that edits the repository.
3. The checker runs `make check` stage by stage, each with its log, and never edits.
4. The quality reviewer reviews the committed diff for bugs and for the project's rules: idiomatic Ruby within Spinel's rules, naming, one public `call` per use case, the layers, and simple code.
5. The security reviewer reviews the committed diff for vulnerabilities. It is the most important gate: it can never be skipped, and a High or Medium finding it is confident in blocks the merge until it is fixed.
6. The benchmark agent compares allocations per key and Spinel's analysis rounds with `main`, and time per key when editor code changed.
7. Whatever blocks goes back to the contributor, and every later phase runs again on the new commit, at most three times before the run stops and asks.
8. The contributor archives the OpenSpec change, pushes once, and opens the pull request from the template. The CI watcher waits for CI; a red run goes back to the contributor with its log. The merger squash-merges, and the reporter writes a report in a fixed shape that names any rule broken.

Rules are checked, not remembered. `tools/gates.sh` refuses a commit without its single co-author trailer, a link, an email address, a session id, or a model name in the diff, the commits, or the pull request; a snapshot not written by the test runner; a new file missing from the code map; a new command, binding, option, make target, or process change without this README; a second push without a CI failure to fix; and a merge without a recorded security review of the reviewed commit.

The run state of a change, `build/pipeline/<change>.json`, records each phase and the commit it finished at, every check stage, the reviews, the pushes, the pull request, and CI. It is written only by `tools/run_state.sh`, so an interrupted run picks up where it stopped.

To start or resume a change, run `/deliver` followed by a change name or a short description in Claude Code; `/status` shows the running change and its next phase. Outside Claude Code the same checks run with `make check`, `make gates`, and `sh tools/run_state.sh status`. A planner with a queue, a history of metrics, and periodic reviews of the code arrive in a later change.
