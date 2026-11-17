fix(buffers): show control characters of a buffer name in caret notation

## Summary

Shows a control character in a buffer's name in caret notation in the `:ls` listing and in the E162 refusal, so a newline in a file name reads as `^J` instead of breaking the message into forged lines. It also injects the one tab list into the three use cases that still reached it through `BufferList#tabs`, and corrects five stale comments and an 83-column comment line, as part a of the backlog item split by the user's split rule.

---

## Changes

- Add `Domain::ControlText.caret`, which shows each C0 control and DEL as a caret and the character 64 above it, and use it for the buffer name in `:ls` and in E162 (security Low, confidence 4)
- Add the buffer-list requirement that a control character in a buffer's name is shown in caret notation in the listing and in E162, with tests in `test/editor_buffers.rb` for a newline name in both
- Change `DeleteBuffer`, `ListBuffers`, and `CloseOtherWindows` to take an injected `tabs:` built with the one tab list in `EditorAssembly`, checked in `test/adapters_assembly.rb`
- Fix the stale comments of `close_tab.rb`, `close_other_tabs.rb`, `window_requests.rb`, `layout_node.rb`, and `buffer.rb`, and rewrap the 83-column comment of `scroll_request.rb`
- Document `caret` in the `ControlText` entry of the code map
- Record the plan, the metrics history row, and the review findings, and queue part b as `windows-buffers-walk` in the backlog pool

---

## Testing

- Run the security review of the committed diff, passed with no High, Medium, or Low finding
- Run the checker's stages docs-lint, dev-build, test-build, test-run, diagnose, bench-budget, metrics, tools-test, and gates, all pass
- Run the quality review, passed with no blocking finding and five advisories
- Run the benchmark against main's recorded figures, passed with allocations held
- Run make spec-validate after the archive, 53 passed and 0 failed

---

## Notes

Part b, the one walk for the five methods of `TabList` and `BufferList` that each visit every window of every tab page, is left for `windows-buffers-walk` in the backlog pool, which keeps its backlog heading. The `:e` and `:w` messages still quote a raw path and are recorded as a finding for a follow-up.
