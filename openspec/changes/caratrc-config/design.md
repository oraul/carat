# Design

## Context

See proposal.md for why. Today `config/default.json` is embedded in the binary as text by `bin/carat-gen-config.rb` and parsed at startup with `Carat::Json` into an untyped nested hash, which `Options.from_config`, `Keymap.leader_from`, `Keymap#add_checked`, and `PluginRegistry#activate_all` each pick apart; problems carry the file name and a JSON path. `ConfigPort` returns that hash and a single `source`. Plugin manifests declare bindings in the JSON keymap shape and option defaults as a hash of text, and `Host#open_scratch` takes a JSON-shaped keymap. `config/plugins.json` lists the compiled plugins for the generated registry. No user or project file is read yet.

## Goals / Non-Goals

**Goals:**
- One line format for the defaults, the user and project files, plugin manifests, scratch keymaps, and the plugin list, read by one parser.
- A typed configuration value, so no untyped hash crosses from the configuration into the library and the analysis budget stays at 2 rounds.
- Every problem located by file and line, reported in file order.
- Startup no slower than with JSON (within 10 percent from launch to the first frame).

**Non-Goals:**
- Reloading, `:set` beyond today's, local options, and running the language commands.

## Decisions

### The parser walks bytes and yields words
`Domain::RcParser.parse(text)` reads one line's text by `getbyte` and cuts words with `byteslice`, so no one-character string is made in a loop. It returns an `RcParse` value: the key, the value words (`Array[String]`), and an error (`""` when the line is good, and a blank or comment line has an empty key). A quoted word appends the slices between escapes to a mutable string. Control bytes other than tab are refused, which keeps escape sequences from a file out of the message row. The parser knows no scope: what a value must be depends on the setting, so it gives words and the reader of each scope checks them.

Alternative: typed values (integer, bool, string, list) decided by the parser. Rejected: `true` is a string for a string option and a number is a word for a key binding (`keymap.normal 0 cursor.line_start`), so only the setting knows.

### `Config` is the typed value the port returns
`Domain::Config`, a `Struct` record, holds the `RcLine` values (source label, file ordinal, line number, key, words) of every file in load order and the problems found, each kept with an order key (file ordinal and line number) so `problems` lists them in file order whichever reader found them. `Config#read(source, text, trusted)` splits the text into lines by bytes, parses each, checks the scope (`option`, `keymap`, `plugin`, `language`), validates `language` lines completely (they have no other reader yet; untrusted text, the project file, may not set them), and keeps the rest. `Config#note(line, message)` records a problem from a later reader. `Config#leader` is the last `keymap.leader` value.

The readers stay where the knowledge is: `Options.from_config` checks option names and types against a table of the Vim names; `Keymap#add_checked` checks modes, word counts, key notation, and action names against the action table and the plugins; `PluginRegistry#activate_all` checks plugin names, `enabled`, and option names and types against the manifests. Each notes its problems on the config. `RcValue` holds the one rule for each of the four value kinds (bool, integer, string, list), its message (`takes true or false`, `takes a number`, `takes one word`), and the text a plugin receives, used by options, plugins, and manifests alike.

Alternative: a merged hash per scope built at load. Rejected: it would lose line numbers or need a parallel structure, and it would be untyped again.

### The gateway reads the three files through `FilePort`
`Adapters::RcConfigGateway` replaces `JsonConfigGateway`. It reads the embedded defaults as `config/default.caratrc`, then `home + "/.config/carat/caratrc"` as `~/.config/carat/caratrc`, then `cwd + "/.caratrc"` as `.caratrc` (untrusted), each only when `stat` says a file is there, and notes a file that exists but raises on read. `FilePort#home` is new: `DiskFiles` reads `HOME` (empty when unset, which skips the user file), `MemoryFiles` keeps one a test can move. No environment is read outside the driver. The gateway holds the file port the assembly receives, so the shared-instance test covers it.

`ConfigPort#load` returns the `Config`; `source` goes, since every line carries its file. `FixedConfig` holds a `Config`; `FixedConfig.defaults` reads the embedded defaults and `FixedConfig.with(text)` reads the defaults and then the given text as the project file, which is how editor tests set options and bindings with typed strings.

### Leader and the top-level JSON keys
`leader` becomes `keymap.leader <Space>`, a keymap setting written in key notation (Vim's `mapleader` is a variable, not an option). `timeoutlen`, `theme`, and `icons` become `option.timeoutlen`, `option.theme`, `option.icons`. `languages` becomes `language.<name>.lsp` and `language.<name>.formatter`, lists. The options the editor does not read yet (`ignorecase`, `smartcase`, `hlsearch`, `incsearch`, `wrap`, `clipboard`) are in the option table with their types, so the defaults keep them and a typo is still caught.

### Plugin manifests use lines (plugin API 2.0)
`Manifest#bindings` is a list of `keymap.<mode> <keys> <action>` lines and `Manifest#options` a list of `plugin.<name>.<option> <value>` lines, one per declared type; `Host#open_scratch` takes keymap lines too. `Keymap#add_lines(lines, leader, owner)` and `Keymap.from_lines` parse them with the same parser and the same binding code as the configuration. `PluginRegistry` applies a plugin's default option lines first and the configuration's `plugin.<name>.*` lines after, through the same `RcValue` checks, so a default and a user line are one format. Changing member types breaks compiled plugins written for 1.x, so the version is 2.0, and the host refuses 1.x manifests with its usual message. Option values still reach the plugin as text (lists joined by newlines), so `Host#option` and the plugins' readers do not change.

Alternative: keep hashes in the manifest and accept lines only in files. Rejected by the request for one format.

### The plugin list is its own file
`config/plugins.caratrc` holds `plugin.<name> <path> <class>` lines. A separate file keeps the runtime configuration free of lines that are not settings (a `plugin.<name>` line with two words would otherwise need a special case in the registry's checks) and lets the generator read a few lines to render the registry. `RegistrySource.render` takes the `Config` of that file.

### The generated mirror
`carat/domain/default_config.rb` holds `DEFAULT_CARATRC`, the defaults text in a single-quoted heredoc, written only when it changes. The generator reads `config/default.caratrc` into a `Config` first and exits non-zero on a malformed line, before writing anything. `test/config_sync.rb` compares the text, checks that the defaults have no parse problem and bind every mode, and that every `plugin.<name>` line names a listed plugin.

### Problems at startup
The assembly reads `config.problems` after the options, plugins, and keymap have read the config, and shows the first with the count of the others, as before. Plugin conflicts and manifest refusals stay in the host's errors, which are not configuration problems.

## Risks / Trade-offs

- [A malicious project `.caratrc` rebinds keys] → It can only bind keys to editor actions and replays, which the user sees; it cannot name a program (`language.*` refused) and cannot write outside what the user's keys do. Recorded for item 9 and the language services change: any future setting that runs a program must be refused in the project file too.
- [Breaking plugin API] → All plugins in the repository move to 2.0 in this change; the refusal message names both versions.
- [Users with a JSON file] → The file is no longer read and nothing warns; the project is pre-release and there were no user files before this change (item 9 had not landed), so only the defaults move.
- [Startup cost] → The defaults are about 500 short lines; the byte parser allocates the words and one value per line, comparable to the JSON parse it replaces. Measured against c4ea5d0 before merging.

## Migration Plan

`config/default.json` is converted line for line, in its order, to `config/default.caratrc`, and `config/plugins.json` to `config/plugins.caratrc`. Rollback is reverting the squash commit.
