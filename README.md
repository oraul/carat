# carat

A terminal IDE written in Ruby with Neovim's modal editing model, built, tested, and shipped with Spinel. `docs/architecture.md` holds the design and the roadmap; `CLAUDE.md` holds the commands and conventions.

Today it is an editor with split windows, tab pages, a plugin host, and a file tree: normal, insert, operator-pending, command-line, and the charwise, linewise, and blockwise visual modes (`v V <C-v>`, `o O gv`, every motion and text object, and `d x y c s > < J gJ p P r ~ u U X D C S R Y I A` on the selection); counts, the `"x` register prefix, and Neovim's `[count] operator [count] motion` grammar; the motions `h l 0 ^ $ f F t T ; , j k G gg + - _ w W b B e E ge gE ( ) { } H M L`; the text objects `iw aw iW aW is as ip ap` and the bracket and quote objects; the operators `d c y > <` with `dd cc yy >> <<` and `x s S C D Y J p P`; the unnamed and named registers; insert-mode editing; the window commands `<C-w>s v h j k l w W p c o = q`, `gt`, and `gT`; and the ex commands `:w :q :wq :x :wa :qa :wqa :xa :e :sp :vs :new :vnew :close :only` and `:tabnew :tabedit :tabclose :tabonly :tabnext :tabprevious :tabfirst :tablast`. Compiled plugins add actions, ex commands, and side windows through the API in `docs/plugins.md`; the built-in `explorer` plugin, the file tree below, is built on it. `docs/compatibility.md` lists every Neovim command it implements with its test, and `docs/backlog.md` the known items left for later changes.

## Building

The prerequisites are a C compiler, `make`, `git`, and `curl`. No Ruby interpreter is needed, not even to build the compiler.

1. `make toolchain` fetches the pinned Spinel commit into `tmp/.spinel`, builds it, and installs `spinel`, `spin`, and `spinel-doctor` under `tmp/.toolchain`. Both directories are ignored by git, every `make` target finds the toolchain there on its own, and `make toolchain-clean` removes them.
2. `make build` compiles the editor to `build/bin/carat` and prints the alias line to add to your shell profile to run it from anywhere; `make install` puts it on the `PATH` instead.
3. `make check` builds, regenerates the config mirror, and runs the tests and `spinel-doctor`; run it before every push.

| Command | What it does |
| --- | --- |
| `make doctor` | Check that `spinel`, `spin`, a C compiler, and `node` are on the path |
| `make toolchain` | Fetch, build without Ruby, and install the pinned Spinel commit under `tmp/` |
| `make toolchain-clean` | Remove `tmp/`, the Spinel checkout and the installed toolchain |
| `make build` | Compile `bin/*.rb` into `build/bin` and print how to run it from anywhere |
| `make run FILE=path` | Build and run the editor on a file |
| `make test` | Build, then run every test program against its snapshot |
| `make lint` | Run the lint test program only |
| `make types` | Print the signatures Spinel inferred |
| `make diagnose` | Run `spinel-doctor` on every compile root |
| `make snapshots` | Rebuild the test programs and rewrite their snapshots |
| `make gen-config` | Regenerate the default config mirror and the plugin registry |
| `make check` | Build, gen-config, test, and diagnose |
| `make spec-list`, `make spec-validate`, `make spec-update` | The OpenSpec commands |

## File tree

`<leader>e` (Space, then `e`) or `:Explorer` opens a file tree in a 30-column window at the left, rooted at the directory you started Carat in, with the current file revealed and marked; the same key focuses the tree when it is open and closes it when it is focused. `:ExplorerFind` reveals the current file in the tree. Inside the tree:

- `<CR>` or `l` opens a file in the window you came from, or expands a directory; `h` collapses or goes to the parent; `o` toggles a directory.
- `s`, `v`, and `t` open the file in a horizontal split, a vertical split, or a new tab page.
- `a` creates a file next to the entry, or a directory when the name ends with `/`; `r` renames; `d` deletes a file or an empty directory after asking `y` or `n`. The name is typed on the command line, Enter confirms, Escape cancels.
- `R` refreshes, `H` shows dot files, `-` moves the root up, `C` makes the directory under the cursor the root, `q` closes the tree, and `?` shows these keys.
- `j`, `k`, `gg`, `G`, and the `<C-w>` commands work as in any window; `:q` in the last file window quits even while the tree is open.

The tree draws its folders and file types with the icons below, so it reads well with or without a Nerd Font. Its options live in your configuration:

```json
{ "plugins": { "explorer": { "options": { "width": 30, "side": "left", "show_hidden": false, "ignore": [".git", "build", "tmp"] } } } }
```

`side` is `left` or `right`, `show_hidden` lists names starting with a dot from the start, and `ignore` names entries the tree never lists. Set `"enabled": false` in that entry to turn the tree off, and bind `<leader>e` to something else in `keymaps` to free the key. Carat reads only its built-in defaults today: the user and project configuration files arrive with the `options-and-config` roadmap item, and until then these values are changed in `config/default.json` before `make gen-config` and `make build`.

## Icons and Nerd Fonts

The file explorer, the diagnostics, and the plugins draw small icons: folders, file types, error and warning markers. By default they come from a Nerd Font, a font family that adds thousands of such glyphs to a programming font. The font is optional: the editor is fully usable without one, see the `icons` option below.

To use the icons, install a Nerd Font and select it in your terminal. JetBrainsMono Nerd Font is a good choice.

- macOS: `brew install --cask font-jetbrains-mono-nerd-font`, then pick "JetBrainsMono Nerd Font" in the terminal's profile settings.
- Arch Linux: `pacman -S ttf-jetbrains-mono-nerd`.
- Other Linux distributions: download the `JetBrainsMono` archive from the Nerd Fonts project's releases, unpack it into `~/.local/share/fonts/`, and run `fc-cache -f`.
- Windows: install the font on the Windows side (unpack the same archive and select the font files, then "Install") and choose it in Windows Terminal's profile, so a terminal running Carat under WSL draws with it.

Then select the font in the terminal: in iTerm2, Terminal.app, Windows Terminal, GNOME Terminal, Konsole, Alacritty, WezTerm, kitty, and the others, the font is a setting of the profile or the configuration file; the terminal, not Carat, draws the glyphs.

Without a Nerd Font the icon cells show boxes or blanks. Set the `icons` option in your configuration to another set instead:

```json
{ "options": { "icons": "unicode" } }
```

`unicode` uses triangles, bullets, and geometric shapes that common terminal fonts already have, and `ascii` uses plain characters such as `+`, `-`, `*`, and `!`. The default is `nerd`. Plugins ask for icons by name, so the option switches every icon in the editor.
