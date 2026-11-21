# Backlog: carat/use_cases/plugins/file_requests.rb

## Plugin directory reads skip the tree-root check

- Where: `list_dir` and `stat` in `carat/use_cases/plugins/file_requests.rb` line 34 at 847851d. Periodic security Low (3). Queue item: backlog items, plugin host classes.
- Why it matters: unlike the write requests through `ResolveInside`, a plugin can list and probe directories anywhere.
- Fix outline: pass the root and resolve the read requests inside it, with a refusal row.
- Category: security
- Added: 2026-11-09

## Plugin file reads and listings are not contained in a root

- Where: `carat/use_cases/plugins/file_requests.rb` line 71, the `read_file` and `list_files` requests. Security review of `file-finder`, Low (3).
- Why it matters: unlike the make, rename, and delete requests, which check that the path is inside a root, an enabled plugin can read the first 1000 lines of any regular file under 256 KiB the user can read (for example `~/.ssh` keys) and list any directory tree. Every plugin is compiled in and trusted today, so this only hardens the plugin boundary.
- Fix outline: have `read_file` and `list_files` take a root like the mutating requests, resolve the path with `ResolveInside` or `real_path` plus `Paths.inside?` before reading or walking, and have the finder pass its working-directory root, with a refusal row.
- Category: security
- Added: 2026-11-10

## The finder's file cap has no test

- Where: `carat/use_cases/plugins/file_requests.rb` line 64, the `MAX_FILES` cap of `list_files` (`ListTree`'s limit and the `Listed the first N files` message the finder shows). Quality review of `file-finder`.
- Why it matters: the cap and its message can break unnoticed.
- Fix outline: test `ListTree#call` with a small limit in `test/use_cases_plugin_files.rb` and the message at the cap.
- Also: test/use_cases_plugin_files.rb
- Category: plugins
- Added: 2026-11-10

## spinel-rebump quality advisory at carat/use_cases/plugins/file_requests.rb:4

Match the existing style: the domain require is wedged between the `../files` use-case requires instead of grouped with the inner-layer requires, which hides the layer order the requires otherwise show. Fix outline: move it up beside `plugin_api` and `ports/file_port`.
- Category: plugins
- Added: 2026-11-14

### run_program lives in the FileRequests family
- Location: carat/use_cases/plugins/file_requests.rb:23
- Why: running a program lives in FileRequests, a family named for files, so its name and doc no longer say what it holds.
- Fix: move run_program into its own ProgramRequests family, or rename the family at the sprint-end review.
- Category: plugins
- Added: 2026-11-16

### Three comments wrap past 72 columns in file_requests.rb and the gateway

- Location: carat/use_cases/plugins/file_requests.rb:25 (94 columns) and :131 (breaks after "copied, so the"); carat/adapters/json_rpc_language_gateway.rb:33 (94 columns). Sprint-11 review, quality advisory.
- Why: the files' 72-column wrap, restored elsewhere in sprint-11, is broken again.
- Fix outline: rewrap the three paragraphs.
- Also: carat/adapters/json_rpc_language_gateway.rb
- Category: plugins
- Added: 2026-11-17

### The capture deadline is spelled in the message and git_signs (sprint-16 sweep quality)

- Location: carat/use_cases/plugins/file_requests.rb:144, carat/drivers/process_runner.rb:27 (CAPTURE_SECONDS), git_signs TIMEOUT.
- Why: changing the deadline silently desyncs the "ran past 2 seconds" text.
- Fix outline: one domain constant the driver uses and the message is built from.
- Also: carat/drivers/process_runner.rb
- Category: plugins
- Added: 2026-11-18

### carat/use_cases/plugins/file_requests.rb:144: the message "ran past 2 seconds" repeats ProcessRunner::CAPTURE_SECONDS (carat/drivers/process_runner.rb:30) (sprint-22 sweep quality)

- Location: `carat/use_cases/plugins/file_requests.rb:144`
- Why: the message "ran past 2 seconds" repeats ProcessRunner::CAPTURE_SECONDS (carat/drivers/process_runner.rb:30), and git_signs matches the text (carat/plugins/git_signs/plugin.rb:42,182), so changing the deadline quietly breaks git_signs backing off
- Fix: report the timeout as a TextResponse field, or as one PluginApi constant for the seconds and the message, and have git_signs check that
- Also reported: sprint-22 sweep note 60
- Also: carat/drivers/process_runner.rb, carat/plugins/git_signs/plugin.rb
- Category: plugins
- Added: 2026-11-20

### The plugin timeout is told by a literal message (sprint-24 sweep quality)

- Location: `carat/use_cases/plugins/file_requests.rb:144`, `carat/plugins/git_signs/plugin.rb:42`, `carat/plugin_api.rb:693`, `carat/drivers/process_runner.rb:30`
- Why: "ran past 2 seconds" restates CAPTURE_SECONDS and GitSigns matches its suffix, so a changed deadline silently breaks both.
- Fix: a PluginApi constant or a timed-out flag on TextResponse, derived from the one deadline.
- Also: carat/plugins/git_signs/plugin.rb, carat/plugin_api.rb, carat/drivers/process_runner.rb
- Category: plugins
- Added: 2026-11-21

### The trusted= comment says activation decides trust (sprint-24 sweep quality)

- Location: `carat/use_cases/plugins/file_requests.rb:59`
- Why: PluginHost#prepare_all decides it before any activation.
- Fix: correct the comment.
- Category: plugins
- Added: 2026-11-21
