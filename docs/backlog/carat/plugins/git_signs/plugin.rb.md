# Backlog: carat/plugins/git_signs/plugin.rb

### git_signs tests counts.length == 2 twice
- Location: carat/plugins/git_signs/plugin.rb:76
- Why: the same condition is tested twice.
- Fix: return early with the branch text when counts.length != 2, then read both counts.
- Category: plugins
- Added: 2026-11-16

### BRANCH and COUNTS repeat git_signs' safety arguments

- Location: carat/plugins/git_signs/plugin.rb:27, :28. Sprint-11 review, quality advisory.
- Why: both repeat the same four safety words (-c protocol.ext.allow=never -c core.fsmonitor=false), so a third git command, such as the diff capture of git-signs-status-b, could leave them out.
- Fix outline: build both from one safety prefix constant, as test/editor_git_signs.rb already holds SAFE.
- Also: test/editor_git_signs.rb
- Category: plugins
- Added: 2026-11-17

### git_signs detects a timed-out capture by matching a message suffix spelled twice
- Location: carat/plugins/git_signs/plugin.rb (TIMEOUT, the timeout check in run) and carat/use_cases/plugins/file_requests.rb (the run_program failure message)
- Why: the plugin recognizes a timeout only by the suffix "ran past 2 seconds", which file_requests.rb writes again as a literal that also restates ProcessRunner::CAPTURE_SECONDS, so rewording the message or changing the deadline silently disables the back-off and every later event stalls again.
- Fix: name the suffix once as a PluginApi constant that run_program builds its message from and the plugin matches, deriving the seconds from the one deadline constant.
- Also: carat/use_cases/plugins/file_requests.rb
- Category: plugins
- Added: 2026-11-17

### git_signs buffer_close drop has no test
- Location: carat/plugins/git_signs/plugin.rb (the buffer_close subscription and drop), test/editor_git_signs.rb
- Why: forgetting a closed buffer's HEAD text and clearing its signs is new behavior with no test, so a regression that keeps stale text or leaks held texts would pass the suite.
- Fix: add an editor_git_signs case that closes a buffer and checks that a reopen at the same HEAD key captures the text again.
- Also: test/editor_git_signs.rb
- Category: plugins
- Added: 2026-11-17

### git_signs keeps old signs when a buffer's relative path becomes empty
- Location: carat/plugins/git_signs/plugin.rb (focus and save return early on an empty relative_path)
- Why: a buffer renamed to a path outside the working directory (for example under an explorer root elsewhere) keeps its previous signs and held HEAD text, against the rule that a buffer outside the working directory shows no sign.
- Fix: call drop(buffer) when relative_path is empty, with an editor_git_signs case covering the rename.
- Category: plugins
- Added: 2026-11-17

### git_signs head_key is empty in a linked worktree or a repository subdirectory
- Location: carat/plugins/git_signs/plugin.rb (head_key)
- Why: when .git is a file (a git worktree) or the working directory is below the repository root, the key is always empty, so every focus runs three git commands, and one timed-out capture stops git for the whole session because the empty key never changes.
- Fix: follow the gitdir: line of a .git file and search upward for the repository root, or record the limit in docs/compatibility.md and the git-status spec and let a timeout back off for a bounded time instead of until a key change.
- Also: docs/compatibility.md
- Category: plugins
- Added: 2026-11-17

### git_signs counts stay stale after a fetch

- Location: carat/plugins/git_signs/plugin.rb:127 (sprint-12 review, quality).
- Why: the focus fast path skips the COUNTS run, but a git fetch moves refs/remotes and FETCH_HEAD, which head_key does not read, so ahead and behind counts stay stale until the next open or save, where before sprint 12 every focus refreshed them.
- Fix outline: add the upstream ref's or FETCH_HEAD's stamp to head_key, or state the trade-off in openspec/specs/git-status/spec.md.
- Also: openspec/specs/git-status/spec.md
- Category: plugins
- Added: 2026-11-17

### git_signs shows no signs for a file committed empty

- Location: carat/plugins/git_signs/plugin.rb:149 (sprint-12 review, quality).
- Why: an empty blob and a file not in HEAD both come back empty from run(), and show_signs returns on no head lines, so an edited file committed empty shows no signs although LineDiff marks it all added.
- Fix outline: record whether cat-file succeeded beside the held text and pass an empty HEAD as zero lines, with a test/editor_git_signs.rb row.
- Also: test/editor_git_signs.rb
- Category: plugins
- Added: 2026-11-17

### git_signs runs git on every focus outside a repository root (sprint-16 sweep quality)

- Location: carat/plugins/git_signs/plugin.rb:128
- Why: the no-git focus shortcut needs a non-empty HEAD key, so from a repository subdirectory every window_focus runs symbolic-ref, rev-list, and cat-file on the editor thread, each up to 2 s, and outside a repository a symbolic-ref per focus; untested.
- Fix outline: remember an empty key and skip a focus whose text is held, or settle the git dir once at activate, with a test.
- Category: plugins
- Added: 2026-11-18

### git_signs keeps four parallel arrays (sprint-16 sweep quality)

- Location: carat/plugins/git_signs/plugin.rb:65 (@buffers, @keys, @paths, @texts).
- Why: keep, drop, held?, and held_text must keep four arrays in step.
- Fix outline: one small Struct record per held buffer in one list.
- Category: plugins
- Added: 2026-11-18

### carat/plugins/git_signs/plugin.rb:195: head_key reads .git/HEAD under the working directory, so in (sprint-22 sweep quality)

- Location: `carat/plugins/git_signs/plugin.rb:195`
- Why: head_key reads .git/HEAD under the working directory, so in a git worktree (where .git is a file) or a subdirectory of a repository the key is always empty and every window_focus runs git up to three times on the editor thread, since the focus shortcut at line 128 needs a non-empty key
- Fix: resolve the git directory once on activation (git rev-parse --git-dir) and key on it
- Category: plugins
- Added: 2026-11-20

### GitSigns repeats its safe git prefix (sprint-24 sweep quality)

- Location: `carat/plugins/git_signs/plugin.rb:43`
- Why: BRANCH, COUNTS, and TEXT each spell the protocol and fsmonitor options.
- Fix: one SAFE_GIT prefix constant.
- Category: plugins
- Added: 2026-11-21
