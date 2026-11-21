### RECORDS_RE still names the removed docs/backlog.md

- Location: `tools/rules.sh:70`, the `docs/(backlog|queue-feature|queue-backlog|goals)\.md$` alternative of `RECORDS_RE`, and its comment at `tools/rules.sh:63`.
- Why: backlog-per-file removed `docs/backlog.md`; the alternative now matches no file, and the brief left the merge gate's rules untouched, so a later rules change removes it alone.
- Fix: drop `backlog|` from the alternative and the file from the comment, with the `records_case yes docs/backlog.md` case of `tools/tools_test.sh` turned to `no`.

### The feature lane queue names the retired docs/backlog.md

- Location: `docs/queue-feature.md:3` ("folded findings are in `docs/backlog.md`"); `RETIRED_QUEUE` in `tools/docs_lint.sh`.
- Why: a backlog-lane change may not edit the feature lane's files, so the line stays and docs-lint allows the retired path in a lane queue; the allowance should not outlive the line.
- Fix: the next feature-lane plan writes `docs/backlog/`; then remove `RETIRED_QUEUE` and its grep from `check_paths`, with its two `docs_lint:` lane-queue cases.

### The lane queues exceed QUEUE_BUDGET on main

- Location: `docs/queue-feature.md` (6,884 bytes) and `docs/queue-backlog.md` (11,413 bytes) at 7f96588, against `QUEUE_BUDGET=17969` in `tools/docs_lint.sh`.
- Why: `make docs-lint` fails its queue check on main itself (18,297 bytes), before and after this change, so every branch's docs-lint stage is red until a plan shortens the queues.
- Fix: the next plan folds or shortens queue text (decisions of merged items first) to fit 17,969 bytes, never dropping a finding.

### The delivery prompts still name docs/backlog.md

- Location: `.claude/workflows/deliver-change.js:1670` (the scout area prompt) and `:1706` (the package prompt), each telling an agent never to read `docs/backlog.md`.
- Why: the file is gone, so the rule no longer covers the backlog folder in these prompts; backlog-per-file changed only the rules card line both copies share, and the read rules of every agent are `backlog-per-file-b`'s.
- Fix: in backlog-per-file-b, name `docs/backlog/` in both prompts beside the guard's folder rule.

### Sprint-row fixtures still write docs/backlog.md

- Location: `tools/tools_test.sh`, the `printf '# Backlog\n' > docs/backlog.md` lines of the sprint-row and groom-refusal fixtures (four of them, near the "groomed sprint row" cases).
- Why: groom no longer reads the file, so the lines are inert fixture noise that suggests the old layout.
- Fix: drop them, or write `docs/backlog/_general.md` where a fixture needs a backlog file.

### backlog-move's mismatch refusal has no test

- Location: `tools/run_state.sh`, `backlog_move`, the `cmp -s "$before" "$after"` branch that keeps FILE and dies.
- Why: `file_entries` appends every entry line unchanged, so no fixture makes the folder differ from before plus FILE; the branch guards a future change to the filing, and a regression there would go unseen.
- Fix: let a test inject a filing that drops a line (for example an environment hook naming the filing command), then expect the refusal and FILE kept.

### The lane queues exceeded their shared budget on main after #277
- Location: `docs/queue-feature.md`, `docs/queue-backlog.md`, budget `tools/docs_lint.sh:62` (QUEUE_BUDGET 17969)
- Why: at 7f96588 the two queues were 18,297 bytes together, so docs-lint fails on main and on every lane branch until one lane trims its queue; backlog-per-file trimmed only backlog-lane text (the merged backlog-records-rule's exception and three of its decisions), leaving the feature queue untouched as its brief requires.
- Fix: have plan-apply or the merger's gate refuse a queue rewrite that leaves both lane queues over the shared budget, so a lane's merge cannot push the other lane over it.

### The gates accept a tracked symbolic link under the records-only paths
- Location: tools/gates.sh, tools/rules.sh (RECORDS_RE, docs/backlog/.+\.md$)
- Why: file_entries now refuses to write through a symbolic link under docs/backlog/, but a commit adding such a link still lands as records-only after the security review was recorded; another writer of those paths (plan-apply, history) could follow it.
- Fix: have the merge gates refuse a tracked symbolic link (git ls-files -s mode 120000) under the RECORDS_RE paths, in a rules change of its own since it edits tools/rules.sh or the gate reading it.
