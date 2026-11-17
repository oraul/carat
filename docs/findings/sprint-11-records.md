## Folded windows-tabs-tidy close_window finding is in neither lane queue

- Location: docs/backlog.md:6647 (the folded windows-tabs-tidy finding); carat/use_cases/windows/close_other_windows.rb:10
- Why: the close_window clear of tab.previous never shipped and the comment at close_other_windows.rb:10 is false, yet the finding is in neither lane queue while groom removed the old entry "CloseOtherWindows clears tab.previous a second time" as fixed by windows-tabs-tidy, so the gap can sit unseen.
- Fix: have the planner add it to the windows-buffers-tidy item (close_other_windows.rb:10, buffer_list.rb:369) or queue it alone.

## FloatSpec offset bound test finding is folded but unqueued

- Location: docs/backlog.md:6657; carat test float_spec.rb:61
- Why: "FloatSpec writes its offset bound test twice" is folded but unqueued while its sibling from the same delivery (the 83-column scroll_request.rb line) is pulled into windows-buffers-tidy.
- Fix: add the float_spec.rb:61 heading to that item's Backlog list, or say why it waits.

## Backlog holds the already fixed stale insert acceptance figure entry

- Location: docs/backlog.md:6601
- Why: the folded entry "Lane queues state a stale insert acceptance figure" is already fixed by sprint-11-records (both queues now say insert 26.0 at line 3), so the backlog holds a done item.
- Fix: have the next sprint's groom remove it as fixed, or have the planner list such headings in groom.txt when its queues fix them.

## Groom folds a findings file without a trailing newline as is

- Location: docs/backlog.md:6640 (two folded findings run together with no blank line) and docs/backlog.md:6612 (a double blank line); tools/run_state.sh groom
- Why: groom concatenates a findings file that lacks a trailing newline as is, so entries run together or gain extra blank lines.
- Fix: make groom end each folded file with exactly one blank line, with a tools-test case.

## sprint-11-records proposal miscounts the removed groom headings

- Location: openspec/changes/archive/2026-11-17-sprint-11-records/proposal.md:9
- Why: it says groom removes the 22 headings of build/plan/groom.txt from docs/backlog.md, but only 20 are removed there; the last two duplicates were repeated copies inside docs/findings/ux-fixes-a.md.
- Fix: say 20 headings from docs/backlog.md and 2 duplicate copies in the ux-fixes-a findings file.

## ux-fixes-a history row records no CI minutes

- Location: docs/metrics-feature.tsv:42
- Why: the ux-fixes-a row records ci_min as - though its CI ran green and its ci_stages are recorded, because build/pipeline/ux-fixes-a.json has no metric.ci_min, leaving a hole in the CI-minutes history.
- Fix: have the merge phase always record ci_min (or history derive it from ci_stages) and backfill this row.

## Findings append can duplicate a heading on a retried delivery

- Location: docs/findings/ux-fixes-a.md:1 (removed by groom)
- Why: it held the ProcessPort and benchmark-phase entries twice each, appended twice by a retried or resumed delivery, and only the planner hand-listing them as duplicates kept them out of the backlog.
- Fix: make the findings append (or groom when folding) skip a heading already present, with a tools-test case.

