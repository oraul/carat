refactor(messages): keep echoes out of the history and build it once

## Summary

Keeps the pattern echo of a search out of the `:messages` history and keeps the two-line refusal of a quit over an unsaved buffer whole in it. The echo of every `n`, `N`, `*`, and `#` filled the history while the refusal was dropped for its line feed, and the history was built inside the editor state instead of the assembly.

---

## Changes

- Change `JumpToMatch` to show the pattern echo with `show_output`, so it is not kept, while the wrap message and the search errors are kept as before
- Change `EditorState#show` to keep an error of several lines whole, so `:messages` lists both lines of the unsaved-buffer refusal, and keep a notification with a line feed dropped in `Notices#add`
- Change `MessageHistory` to store texts only, with `add(text)`, one `clear`, and no level list or `level_at`
- Build the history once in `EditorAssembly` and pass it as a required `message_history:` keyword to `EditorState` and `Notices`
- Add editor test rows for an `n` echo absent from `:messages`, the wrap message kept, and the refusal shown on two lines, and update the domain and assembly tests
- Document the two rules in the `messages` spec, the README, `docs/compatibility.md`, and `docs/codebase-map.md`
- Append this lane's metrics history row and take the change out of the backlog queue

---

## Testing

- Run the security review on the committed diff, pass with no High, Medium, or Low finding
- Run the quality review, no findings added
- Run every stage of `make check` at the implementation head, all pass
- Run the benchmark against `main`, pass with nothing blocking
- Run `make spec-validate` after the archive, all pass

---

## Notes

None
