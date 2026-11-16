# Design

## Context

Every phase of `.claude/workflows/deliver-change.js` runs in the main checkout, whose branch the resume start checks out; `tools/run_state.sh` reads `build/pipeline` and `build/stages` relative to the working directory, and the Makefile reads the toolchain at `$(CURDIR)/tmp/.toolchain` and the compile cache at `$(CURDIR)/build/spinel-cache`. The merger's green line adds a worktree of origin/main at `tmp/.merge-gates` and runs its gates against the local HEAD. The agent guard, run from origin's main, admits `cd`, `git -C`, and `make -C` into a worktree `tmp/.NAME` of the project, judging paths from the project root.

## Goals / Non-Goals

Goals: each delivery in its own worktree under a hidden `tmp/` directory, sharing the toolchain, compile cache, and run states; a moved main merged in with both sides' appended rows; distinct merge-gates paths. Non-goals: running two deliveries of one lane, or a records change beside another; any change to the merge gates or `tools/rules.sh`.

## Decisions

- Path `tmp/.lane-CHANGE`: one segment under `tmp/` matches the guard's existing worktree rule, so the agents' `cd tmp/.lane-CHANGE && ...` is admitted with no guard path change, and the guard's checks of a worktree's `.git` record still apply.
- Links, not environment: `lane-open` links `tmp/.spinel`, `tmp/.toolchain`, `build/spinel-cache`, `build/pipeline`, `build/stages`, and `build/plan` from the main checkout, so every relative path the Makefile, the run state script, and the agents use reaches the shared copy with no variable to pass. The guard's write rule already resolves links, so the body file is written at the main checkout's `build/pipeline/`.
- Every link target is made first when missing, and the resume runs `make doctor` and `make toolchain` in the main checkout before `lane-open`, so a first run on a fresh checkout links the one toolchain rather than leaving the lane without one or building a second.
- `lane-close` removes the links before `git worktree remove --force`, so no removal can follow one into the shared toolchain or run states.
- The merger's step 7 runs in the main checkout, never in the lane: `lane-close` removes the lane, which would leave the shell in a removed directory, and `git checkout main` succeeds only where main is checked out, the main checkout.
- Merge gates under the lane: the green line starts with `cd tmp/.lane-CHANGE &&`, so its `tmp/.merge-gates` is the lane's own and the gates see the branch as HEAD; when the cd fails, the rest runs in the main checkout, where the gates refuse a HEAD other than the pushed head.
- Union by an attributes file of the merge alone (`git -c core.attributesFile=...`): a tracked `.gitattributes` would be a repository path tools-test reads, which TOOLS_RE in `tools/rules.sh` does not hold, and the brief forbids editing that file here.
- `merge-main` at the start of each implement and fix start, not at the push: the merge commit then goes through the checker and both reviews like any other commit, and the push and merge gates see the head they covered.

## Proposed CLAUDE.md wording

Not applied: an agent's instruction does not authorize an edit of CLAUDE.md. These lines replace the Agents section's contributor, planner, Sprints, Backlog, and Run state bullets and the Commands section's run state bullet, and add a Lanes bullet after Run state; with them the file is 30,714 of 30,720 bytes.

    - `contributor`: the only agent that edits, every start given only the brief: proposes and applies through OpenSpec, fixes what comes back, archives, commits the gated pull request text as the archived change's `pr.md` and pushes, from which `open-pr.yml` opens or updates the pull request (`tools/open_pr.sh`), holding no GitHub tool; stops on a materially ambiguous request, a secret, an irreversible action, or missing context. It self-checks tests, docs, and the brief before returning. One change is one reviewable pull request; a larger one is split.
    - `planner`: orders the lane queues by `docs/goals.md` into `build/plan/<change>/`, citing its tier and a number per decision; an unresolved blocking security finding stops the run; it runs only when `plan-needed` finds a decision to make; an edit of the merge gate's rules (`tools/rules.sh`) goes first, alone. `retrospective`: closes the run in one start: its last records, a total-token overrun, and at most three proposals to simplify the workflow, and runs `review-due`. Neither edits a tracked file. `/plan` previews the planner.
    - Sprints: a sprint of 5 changes, three features and two backlog changes (a bug fix or a tidy-up of findings, docs, or tooling), a pipeline change only for a defect (T0 exempt from both; a line starting `The user-approved exception` under its heading lifts it), each item self-contained. After every merge the main session starts `/sprint`, `.claude/workflows/sprint-planning.js`, which ends at once until `review-due` counts the sprint's fifth merge (`docs/sprints.tsv`); then the security and quality reviewers over the sprint's combined diff, the skeptic (a quality finding it drops is not recorded, a disputed security finding is), the whole-tree `/review` (`periodic-review.js`) every second sprint, and the planner's sprint mode: the grooming and the next queue, which the sprint's records change, `sprint-N-records`, alone applies with `groom` and the sprint's row. A capped or missing review is `partial` or `not-run`, never passed.
    - Backlog: a delivery never reads or greps `docs/backlog.md`: the contributor appends the findings it is handed to `docs/findings/<change>.md` with `>>`, and `plan-apply` the planner's `build/plan/<change>/backlog.md`, which `groom` folds in. Only the planner's sprint mode reads it: duplicates (`backlog-dups`, the model deciding), entries a merged item listed by heading, a security entry leaving only that way or with its fixing commit.
    - Run state: `build/pipeline/<change>.json`, written only by `tools/run_state.sh`, its phases, reviews, and figures only by the workflow; stage logs in `build/stages/<change>/`. A package step commits only its lane's history rows (`history`) and queue (`plan-apply`).
    - Lanes: each delivery runs in its own worktree `tmp/.lane-<change>` (`lane-open`; removed after the merge or when replaced, kept on a stop), sharing the toolchain, compile cache, and run states; `merge-main` takes in a moved main, keeping both sides' appended rows. The main session may start one feature-lane and one backlog-lane delivery at once, never two of one lane, and a `sprint-N-records` change beside no other.
    - `sh tools/run_state.sh COMMAND`: a change's run state, every command in the script's header: `check CHANGE` runs the stages detached, `push CHANGE` pushes after the pre-push gates, and `status` is `/status`.

## Risks / Trade-offs

- Two builds sharing one compile cache at once: the cache is keyed by content, as the check clone's shared toolchain already is.
- A delivery started while the main checkout has its branch checked out fails at `lane-open`, which says to check out main there first; this run's own branch is such a case only until it merges.
