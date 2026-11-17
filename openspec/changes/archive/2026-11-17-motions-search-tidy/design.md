# Design

## Context

Four search bugs and one duplicated cut, all in area 6's search half. The pattern translator `VimPattern` stays one pass with no backtracking construct; the changes are where it decides what a character means and what string `~` stands for.

## Decisions

### The incsearch clamp

`PreviewSearch` moves the cursor with `state.clamp_col(hit.row, hit.col)`, the rule `JumpToMatch` applies on Enter. The preview highlight keeps the match's own columns, so an empty match at the line end is still not drawn.

### ~ in a search pattern

`VimPattern.compile_search(source, ignorecase, smartcase, previous, previous_kept)` builds a non-capturing pattern whose `~` is `previous`, refused with E33 when `previous_kept` is false. The tilde check reads `@tilde_known` alone, so `compile` (with no previous) still refuses and `compile_substitute` behaves as before. The callers that compile a typed search pattern pass the last substitute's string: `FindMatch` and `PreviewSearch` take `last_substitute:`, the one `LastSubstitute` built in `EditorAssembly`; `GlobalCommand` already holds it. `LastSearch#recompile(options, memory)` takes it as well, from `SetCommandHandler`, which gains `last_substitute:`. `*` and `#` keep `compile`, since `escape` writes `~` as `\~`.

### The second caret

`@caret_seen` is set when `^` anchors and cleared wherever `@at_start` is set true again (a branch or a group start). `caret` anchors only when `@at_start && !@caret_seen`; `@at_start` stays true after it so `^*` keeps its literal star.

### One collection scan

`VimPattern.collection_close(text, from)` is the class form of the compiler's `collection_end`: from the byte after `[`, an optional `^`, then a `]` taken as a member, then bytes up to the first `]` not after a backslash, a `[:name:]` class skipped whole; the index of that `]`, or -1. `posix_class_end` becomes `VimPattern.posix_class_close(text, i)` for both. The instance method calls the class one with `@source` and `@pos`; `pattern_end` calls it at a `[` and skips to the byte after the `]`, or past the `[` alone when none closes it, as the compiler then reads a literal `[`.

### The cut and the prefix written once

`DelimitedPattern.typed(text, forward)` cuts what the prompt submitted at the first delimiter of its direction into `pattern` and the offset as `rest`, sharing the cut with `parse`. `SearchPrompt.prefix_of(forward)` is the prompt character; the instance `prefix` and `FindMatch`'s found message use it.

## Risks

- A search pattern holding `~` now compiles after a substitute instead of failing; the substitute tests cover the other callers, and `:g` and `:v` gain rows of their own, since their `~` now matches the last replacement instead of answering E33.
- The pattern end differs only for collections whose first `]` or a `\]` precedes the delimiter; `:s` and `:g` share it through `DelimitedPattern.parse`, which the substitute tests cover.
