# carat

A terminal IDE written in Ruby with Neovim's modal editing model, built, tested, and shipped with Spinel. `docs/architecture.md` holds the design and the roadmap; `CLAUDE.md` holds the commands and conventions.

Today it is an editor with split windows, tab pages, and a plugin host: normal, insert, operator-pending, and command-line modes; counts, the `"x` register prefix, and Neovim's `[count] operator [count] motion` grammar; the motions `h l 0 ^ $ f F t T ; , j k G gg + - _ w W b B e E ge gE ( ) { } H M L`; the text objects `iw aw iW aW is as ip ap` and the bracket and quote objects; the operators `d c y > <` with `dd cc yy >> <<` and `x s S C D Y J p P`; the unnamed and named registers; insert-mode editing; the window commands `<C-w>s v h j k l w W p c o = q`, `gt`, and `gT`; and the ex commands `:w :q :wq :x :wa :qa :wqa :xa :e :sp :vs :new :vnew :close :only` and `:tabnew :tabedit :tabclose :tabonly :tabnext :tabprevious :tabfirst :tablast`. Compiled plugins add actions, ex commands, and side windows through the API in `docs/plugins.md`; the built-in `hello` plugin (`<leader>hh`, `:Hello`) proves it. `docs/compatibility.md` lists every Neovim command it implements with its test, and `docs/backlog.md` the known items left for later changes.

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
