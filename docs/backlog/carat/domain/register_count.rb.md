# Backlog: carat/domain/register_count.rb

## RegisterCount and SubstituteArgs each read a count

- Where: `RegisterCount.parse` in `carat/domain/register_count.rb` (line 38 at 76fa78b: the digit loop, `MAX_COUNT`, `digit?`, and the blank skipping) and `SubstituteArgs.tail` and `SubstituteArgs.digit?` in `carat/domain/substitute_args.rb`. Quality advisory of `buffer-global`.
- Why it matters: the two readers of an ex count, its cap, and the blanks around it can drift, so `:d 5` and `:s/a/b/ 5` could disagree on what Vim reads the same way.
- Fix outline: share one domain count reader (the count, where it ended, and an error) between `RegisterCount` and `SubstituteArgs`. Queued in `global-tidy`.
- Also: carat/domain/substitute_args.rb
- Category: editor
- Added: 2026-11-05

## RegisterCount re-encodes the writable register names

- Where: `RegisterCount.writable?` in `carat/domain/register_count.rb` (line 71 at 76fa78b). Quality advisory of `buffer-global`.
- Why it matters: it lists again the names `Registers.valid_name?` and `Registers.read_only?` already define, so a register added there would be refused by `:d x` until this copy is updated.
- Fix outline: return `Registers.valid_name?(c) && !Registers.read_only?(c)`; the digits are already excluded before the call. Queued in `global-tidy`.
- Category: editor
- Added: 2026-11-05

## The ASCII digit test is copied in 12 files

- Where: `carat/domain/register_count.rb` (line 66 at fb09c6b) and the inline `b >= 48 && b <= 57` or private `digit?` of `ex_grammar`, `filetype`, `motions`, `vim_pattern`, `substitute_args`, `json`, `replacement`, `rpc_framer`, `registers`, the language gateway, and the Ruby tokenizer. Periodic quality at fb09c6b; the entry on `RegisterCount` and `SubstituteArgs` covers only two of them.
- Why it matters: twelve copies of one test drift independently, and each reader of a count or number must find its own.
- Fix outline: one domain module function used by the domain and adapter copies, the plugin keeping its own as the plugin rule requires, with `make bench` held on the hot paths. Queued in the backlog item of `docs/queue.md` (`clamp` copies and ASCII digit tests).
- Category: editor
- Added: 2026-11-07

### Bounded count parsing and digits? are copied in six places (sprint-16 sweep quality)

- Location: carat/domain/register_count.rb:38, substitute_args.rb:80 (MAX_COUNT :27), ex_range.rb:134 (MAX_NUMBER); digits? in buffer_command_handler.rb:102, tab_command_handler.rb:102, history_command_handler.rb:67.
- Why: 3 bounded decimal loops with their own limits and 3 all-digits predicates, one a regex, drift apart.
- Fix outline: one domain bounded number reader and digits? predicate called by the three parsers and three handlers.
- Category: editor
- Added: 2026-11-18
