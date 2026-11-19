# Design

## One loop, beyond the rounds

`closeAdvisories` runs after `verify` returned true in the package step, so the last quality and security reviews passed with nothing blocking. `openAdvisories` is the run's findings (quality advisories, and security findings of any severity) minus those the reviews confirmed fixed in place. They are offered to one contributor start, `close-advisories`, with `offer(open, true)`, so the reviewers of the next round list the ones the fix removed (`fixed_in_place`); that list gives the figures: closed are the offered findings confirmed fixed, left the rest.

The start is not a fix round: `contributor` increments `rework` only for `fix`, and the start's tool calls and tokens go to their own phase key, `closing`, with the cap `closing` in `CALL_CAPS` (40, like `fix`, so the contributor's `maxTurns` is unchanged). If it commits nothing the loop ends there and no review reruns.

## Reviews of the closing commit

A commit goes through `verify` again, which reuses what exists: `priorQuality` scopes the quality review to the commits since its pass, and `settleFrom`, `settleAfter` and the checker's settled line let a records-only commit stand on the earlier check, security, and bench passes (the gates settle them the same way). Any other commit, code changes included, has no settle, so the check runs in full and the security review runs on the diff. A security finding among those offered turns the settle off, as in an advisory-only round.

## No second loop

`closingLoop` makes `rounds` offer nothing in place, so advisories the closing review raises stay in `qualityAdvisory` and are handed to the package start for `docs/findings/<change>.md`. `closingFigures.closed` being set stops a second call, a resume included, since `seed` reads it back. A blocking finding goes through `mayFix` and `contributor('fix', ...)` within the round limit as before.

## Figures

`metricLine` adds `advisories_closed` and `advisories_left` once set (a skipped loop records 0 and 0). `history_row` appends them as columns 23 and 24 after `weighted_phases`; the `rates` columns read are unchanged and the loop never counts as a rework round.

## Budget

contributor.md stays within its 6,999 bytes: the mode is a heading and a pointer, its rules in `docs/contributor-notes.md`, and a few words elsewhere in the file are shortened with no rule dropped. CLAUDE.md has no room (30,713 of 30,720), so the process is described in README.md.
