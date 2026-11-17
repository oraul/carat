# Design

## Context

- `late_findings` (`tools/run_state.sh`) printed every `note.N` value starting `late-finding `, and `append_history` wrote them as bullets into `docs/findings/<change>.md`, which `groom` folds into the backlog the planner reads. `note` and `set note.N` take any text from anyone running the script, the read profile of the agent guard included, and the run state carries no writer field.
- The workflow writes its late findings at the close, after the merger recorded `merged` and fast-forwarded main, through `noteText`, which keeps `[A-Za-z0-9 .,:;()/_+=#%'?*@-]` and at most 400 characters.
- `open-pr.yml` checks out main with `actions/checkout`, whose default `persist-credentials: true` leaves the job's token in `.git/config` for every later step, the one holding `PR_TOKEN` included. The read step fetches the branch from origin; the repository is public.
- `open_pr.sh wait` sees only `git ls-remote origin 'refs/pull/*/head'`: a number and a commit, no head repository.
- `staleRed` split each check on every comma into four fields.

## Goals / Non-Goals

**Goals:**

- A late finding reaches the findings file only when written by the workflow's close, after the squash commit existed.
- No token stored by the open-pr checkout.
- A fork's pull request sharing the pushed commit is never recorded beside ours.
- A check name with commas parsed whole; one checks form whose workflow field has a stated source.

**Non-Goals:**

- Proving the run state against a process that rewrites the file after the merge; reading pull requests over GitHub's API from the contributor; changing the merger's call cap.

## Decisions

- The squash commit as the provenance mark. A note written before the merge, by branch code a check runs or by an agent before the close, cannot name the squash commit, which does not exist yet. So `note` refuses a `late-finding` while `merged` names no commit on main (`merged_commit`, `merged_on_main`) and stores `late-finding MERGED TEXT`; `late_findings` keeps a note only when its first word equals the run's `merged` value and the rest is in `noteText`'s shape, and names each one left out on stderr. Alternatives: a writer field or an environment variable (forgeable by the same writer), a secret (the next change's package step, which runs `history`, could not hold the workflow's). A note left by an older script without the stamp is left out: the in-flight run of the other lane loses at most its late findings, named on stderr.
- `recordLate` runs only at the close, the two calls before the CI fix's and the resume's review-fix push dropped: every flush joins its records with `&&`, so a refused note would drop the check, review, phase, and figure records after it and stop the run, and `handOver` would have marked those findings handed. A merged close notes them as `late-finding`; an unmerged one after the push (a stalled CI, a lost start) as `held-finding` notes, which the note command accepts before the merge; one stopped before the push (the round limit), whose package step handed nothing yet, as `unpushed-finding` notes, which a resume still unpushed puts back into the list its package step hands over (`addBacklog`, compared as note text so a rerun security review's line is one entry), never into the held ones, so a finding reaches the findings file once. A resume reads those back in `seed` (`heldFindings`, less the texts a merged close already noted late) and its merged close notes them as late findings before the fresh ones, so a stop between the push and the merge loses none: a security Low lives only in a start's memory, and `seed` marks every quality advisory handed once pushed. Alternative: seeding `handed` only from findings noted before the package step, which needs the security Lows' texts in the run state anyway and an order between notes and phases the run state does not keep.
- `persist-credentials: false` on the one checkout. The read step's `git ls-remote` and `git fetch` of a public repository need no credentials; the open step uses `GH_TOKEN` through gh, not git.
- `wait` takes the set of numbers whose head is the pushed sha. One number: recorded. The run state's `pr` among several: kept (a later push of a run whose first wait recorded its own). Otherwise refused with the numbers named, nothing recorded, the message pointing at the open-pr log. Git alone cannot tell a fork's pull request from ours, so ambiguity stops rather than guesses; the residual case, a fork opening a pull request on the pushed commit before open-pr opens ours and before the first poll sees ours, needs the attacker to see the push and act within that window, and is noted here rather than closed.
- `staleRed`: `parts = split(',')`, workflow `parts[0]`, status and conclusion the last two, name `parts.slice(1, -2).join(', ')`, fewer than four parts refused (red stands). A workflow file name never holds a comma.
- The merger's workflow field comes from `actions_list` of the head's workflow runs, each check run matched to its run by check suite, read once before a red or pending return; a green return writes `-`, since only the red path (`staleRed`) and the pending note read the field, and an extra call on green would pass the merger's fixed cap of 12. `staleRed` treats `-` as no workflow, so the red stands.

## Risks / Trade-offs

- A run whose closing note fails because main was not fast-forwarded would lose its late findings; the merger's step 7 fast-forwards main before the close, and `merged_on_main` also accepts BASE.
- A `held-finding` note, like a `quality-advisory` one, is accepted from anyone running the script before the merge, so branch code a check runs could plant one that a merged resume notes late; its text is still held to `noteText`'s shape by `heldFindings` and to `LATE_TEXT_RE` by `late_findings`, and it lands in the change's findings file for the planner's grooming, the same reach a planted advisory has through the package step.
- The fork window of `wait` above remains; the merger's head check (step 1) still refuses a pull request whose head is not the pushed head.
