# Design

## Context

`Process.spawn` with a bare program name searches every `PATH` entry, and an empty or relative entry is the working directory, which is the project's. The finder is a plugin and may require only its own directory, so a sanitizer for its rows must live there.

## Decisions

- The runner resolves the name itself (`program_path`) and passes the absolute path to `Process.spawn`, so the child's own `PATH` search never runs. A name with a slash is passed as given: the use case already refuses one from a plugin, and a language server command with a path is the user's configuration.
- The grep budget counts bytes read (each line and its break), not stored lines, because a listing of files of empty lines stores nothing; reaching it sets the existing cap mark, so the title already says the store is cut.
- `SafeText` holds the old private `safe`, `plain?`, `utf8_size`, and `format_control?` as module functions, so `Grep` and `Plugin` share one sanitizer; a plain path costs no copy, which keeps the finder's allocation budget.
- `LONGEST_SPAN` moves to `Domain::SyntaxLine`, which both span paths already require. A float span starting past it is refused with the existing message; a token starting past it is dropped and a length is cut, as the float path already cut it.
- `TabList#drop_kept` clears every hidden slot window over a buffer, dropping its folds; both the registry's clean-up and `close_scratch` use it, so no hidden slot keeps a view whose buffer left the list.
