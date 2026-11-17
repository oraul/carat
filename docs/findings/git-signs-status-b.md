### git_signs detects a timed-out capture by matching a message suffix spelled twice
- Location: carat/plugins/git_signs/plugin.rb (TIMEOUT, the timeout check in run) and carat/use_cases/plugins/file_requests.rb (the run_program failure message)
- Why: the plugin recognizes a timeout only by the suffix "ran past 2 seconds", which file_requests.rb writes again as a literal that also restates ProcessRunner::CAPTURE_SECONDS, so rewording the message or changing the deadline silently disables the back-off and every later event stalls again.
- Fix: name the suffix once as a PluginApi constant that run_program builds its message from and the plugin matches, deriving the seconds from the one deadline constant.

### git_signs buffer_close drop has no test
- Location: carat/plugins/git_signs/plugin.rb (the buffer_close subscription and drop), test/editor_git_signs.rb
- Why: forgetting a closed buffer's HEAD text and clearing its signs is new behavior with no test, so a regression that keeps stale text or leaks held texts would pass the suite.
- Fix: add an editor_git_signs case that closes a buffer and checks that a reopen at the same HEAD key captures the text again.

### git_signs keeps old signs when a buffer's relative path becomes empty
- Location: carat/plugins/git_signs/plugin.rb (focus and save return early on an empty relative_path)
- Why: a buffer renamed to a path outside the working directory (for example under an explorer root elsewhere) keeps its previous signs and held HEAD text, against the rule that a buffer outside the working directory shows no sign.
- Fix: call drop(buffer) when relative_path is empty, with an editor_git_signs case covering the rename.

### git_signs head_key is empty in a linked worktree or a repository subdirectory
- Location: carat/plugins/git_signs/plugin.rb (head_key)
- Why: when .git is a file (a git worktree) or the working directory is below the repository root, the key is always empty, so every focus runs three git commands, and one timed-out capture stops git for the whole session because the empty key never changes.
- Fix: follow the gitdir: line of a .git file and search upward for the repository root, or record the limit in docs/compatibility.md and the git-status spec and let a timeout back off for a bounded time instead of until a key change.
