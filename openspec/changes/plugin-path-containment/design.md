# Design

## Context

See proposal.md for why. `MakePath` (`carat/use_cases/files/make_path.rb`) already refuses a create whose parent, with links resolved through `FilePort#real_path`, is outside the resolved root, in a private `resolved_inside?`. `RenamePath` and `DeletePath` check only `Domain::PathPolicy.inside?`, which is lexical. `FilePort#rename` and `#delete` act on a link itself and never follow it, so the only way out of the root is through a linked directory above the entry. The plugin host builds the three use cases from the file port and the shared `ProbePath`.

`Keymap#bind_text` turns notation into codes and walks the trie one node per code; `clear_owner` recurses once per level when a plugin's bindings are removed. Every path that adds a binding (the checked configuration, a plugin's manifest lines through `add_lines`, a scratch keymap through `from_lines`) goes through `apply` and `bind_text`; `bind` has no caller.

`Config#note` appends a problem and its order (file ordinal times `FILE_SPAN` plus the line number) to two parallel arrays; `report` insertion-sorts an index by order, stably. The readers note in ascending runs: `read` per line in load order, then `Options.from_config`, the keymap, and each plugin walk the settings in load order, so the noted orders are a handful of ascending runs, interleaved by file and line.

## Goals / Non-Goals

**Goals:**
- One real-path containment check, shared by create, rename, and delete.
- No trie deeper than a fixed bound, whatever the configuration or a manifest holds.
- `report` returns exactly what it returns today, in time that does not grow with the square of the problems.

**Non-Goals:**
- An iterative `clear_owner`: with the bound its depth is at most 65.
- A cap on the number of problems: it would drop reports, and the gateway already bounds a file to 1 MiB.
- Closing the race between the check and the rename or delete; the port has no `renameat` or `openat`.

## Decisions

- `ResolveInside` is a use case in `carat/use_cases/files/` with `call(root, dir) -> bool`: the directory, links resolved, equals the resolved root or lies inside it; false when either cannot be resolved. It is built once in `PluginHost#initialize` from the file port and passed as a required keyword `resolve_inside:` to `MakePath`, `RenamePath`, and `DeletePath`, each keeping a reader so `test/adapters_assembly.rb` can check the three share it and its port is the shared one. Alternatives: a private copy in each use case (three copies of a security check), a concern (it needs the port, and concerns hold behavior only on readers the class provides, which would put the port reader contract into three use cases for one method), or a method on `ProbePath` (a use case has one public method, `call`).
- The check is on the entry's directory, `dirname(source)`, not the entry: the entry may be a link, and renaming or deleting a link acts on the link. A rename's target is `join(dirname(source), name)` and the name holds no separator, so the same directory covers it. It runs after the existence check, as in `MakePath`, so a missing entry keeps `No such file or directory`; on a resolution failure it answers `Outside the tree root`.
- The bound is `Keymap::MAX_KEYS = 64`, checked in `bind_text` after the empty-key check, with the problem `more than 64 keys`. `bind_text` is where every added binding passes, so the configuration notes it as `file:line: ...` and `add_lines` records it in `errors` for a plugin. `bind` is left as it is; it has no caller and takes codes from code, not from input.
- `report` is a natural merge sort: one pass finds the starts of the ascending runs of `orders`, then adjacent runs are merged pairwise until one remains, taking from the left run on equal orders so the noted order of one line's problems is kept. With r runs it costs n log r; r is bounded by the number of reader passes for any real input, and n log n is the worst case. Alternatives: a cap (loses reports, changes the startup count), a counting sort by line number (allocates arrays as long as the file), or keeping one array per file (the order within a file still needs the merge).

## Risks / Trade-offs

- [The check and the rename or delete are two calls; a tree changed between them can still redirect the operation] → Same as `MakePath`; the plugin acts on the user's command in the user's own tree, and the race needs a process writing into it at that moment. Recorded as a non-goal.
- [A user with a binding of more than 64 keys loses it] → Vim users bind a few keys; 64 is twenty times the longest default. The line is reported, not silently dropped.
- [Spinel types an empty array literal as `Array[Integer]`] → the merge uses only integer arrays (indexes and run starts), which is that type, and the strings are copied out at the end as today.
