# Design

## Context

`groom` checks every line of the sprint plan's `groom.txt` before it writes anything; it already knows the sprint in progress through `sprint_state` (`sprint_names`, the changes merged since the last sprint row, and `sprint_base`, the merged commit of the previous sprint's last change) and reads entries through `backlog_entry`. The queue a change was delivered from is read by `queue_at` and `merged_of`, as `exception_item` already does.

## Decisions

- `listed`: membership in `sprint_names` replaces the suffix glob over the archive; a merged change of the sprint is archived by the delivery rules, so the archive check adds nothing. The heading proof reads the item through `queue_items`, which `exception_item` shares (`N. \`CHANGE\` (`, at the merged commit's parent, else at the commit, since a package step may have applied the plan naming it), its continuation lines joined by one space with their indentation dropped, so a heading wrapped at a space still matches; the item ends at a blank line, a heading, or the next numbered item. The heading must stand whole in the item, as the planner quotes it (`Backlog: "### title"`): no `#` before it and, after it, the closing quote, a backtick, a comma, or the end of the item, so a shorter heading that prefixes a longer quoted one is not listed.
- `fixed`: the range is `sprint_base..HEAD`: the commit is an ancestor of HEAD and not of `sprint_base`. HEAD, not origin/main, since the records change grooms on its own branch, which holds main; a `sprint_base` that names no commit refuses every `fixed` line rather than accepting any. The file proof takes the commit's changed paths (`git diff-tree -r --root`, without `-m`, so a merge commit lists no file and proves nothing) and looks for each as a whole token (no path character before it, a `./` prefix allowed, none after but a `.` ending a sentence, that is a `.` followed by no path character) in the heading and its `- Location:` or `- Where:` lines; an entry with neither, such as a group of findings bullets, is read whole.
- Guard: `security (high|medium|low|disputed)s?` bounded by non-letters, or a severity and confidence pair `(high|medium|low) (N)`, any case, the skeptic's `security disputed` kept since a disputed security finding stays, the severity words the security reviewer records (`<severity> (<confidence>)`) and the planner and queue quote (`security Low (6)`, `periodic security Medium (8)`, `security Lows`). A text naming security without a severity, such as a quoted section title, is not a security entry.

## Risks

- An older security entry written with no severity marker can now leave as a duplicate; every recorded security finding carries its severity by the security reviewer's note format, and backlog-pick's own security ordering is unchanged.
- A planner `fixed` line for a fix merged in an earlier sprint is now refused; the planner names such an entry in a later triage or leaves it, which keeps a security entry rather than dropping it.
