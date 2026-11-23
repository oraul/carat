# Proposal

## Why

`:messages` is meant to hold what the user was told, but the pattern echo of every `n`, `N`, `*`, and `#` fills it, while the refusal of a quit over a hidden unsaved buffer (`E37` and `E162` on two lines) is dropped because it has a line feed. The history is also built inside `EditorState` and handed to `Notices` through the state, so the assembly does not own it, it is cleared with two calls, and it stores a level per entry that only tests read.

## What Changes

- A search that finds its match shows the pattern echo with `show_output`, so the history does not keep it; the wrap message, `E486`, and the other errors are kept as before (`JumpToMatch`).
- An error is kept in the history whole even when it has several lines; a non-error text with a line feed is still a listing and is not kept (`EditorState#show`). A notification with a line feed is still not kept (`Notices#add`).
- `MessageHistory` keeps texts only: `add(text)`, no level list, no `level_at`, one `clear`. The `INFO`, `WARNING`, and `ERROR` constants stay, being the levels of notices and messages.
- `EditorAssembly` builds the `MessageHistory` once, hands it to `EditorState` and `Notices`, and exposes it as `message_history`; `EditorState` takes it as a required keyword. The member is named `message_history` on `EditorState` and `Notices`, since `history` reads as the command or search history.
- The `messages` spec states the two rules, and `docs/compatibility.md` and `docs/codebase-map.md` follow.

Out of scope: the other contents of the history, the notification levels, and the wording of any message.

Roadmap: outside `docs/architecture.md` section 12 (a backlog tidy-up of the delivered messages).

Assumptions: the wrap message of a search stays kept, as Neovim keeps it; the two-line refusal stays one history entry holding both lines, as `:messages` lists it.

## Capabilities

### New Capabilities

### Modified Capabilities
- `messages`: an error of several lines is kept whole, and the pattern echo of a search is not kept.

## Impact

- Code: `carat/domain/message_history.rb`, `carat/domain/editor_state.rb`, `carat/domain/notices.rb`, `carat/adapters/editor_assembly.rb`, `carat/use_cases/search/jump_to_match.rb`, `carat/use_cases/ex/messages_command_handler.rb`.
- Tests: `test/editor_messages.rb`, `test/domain_messages.rb`, `test/adapters_assembly.rb`, and every test that builds an `EditorState` or `Notices`.
- Docs: `docs/compatibility.md` (the messages table), `docs/codebase-map.md`.
- README.md: unchanged, it describes no message history rule.
- docs/architecture.md: unchanged, it names no message history rule.
