# Design

## Context

`make bench-budget` builds `bench/keys.rb` at `-O 0` and calls `bench/run.sh --budget lh $(ALLOC_BUDGET)`, which runs the scenario at SMALL and LARGE keys and compares the difference of the object totals per key with one maximum, then prints `grep`. `make bench` passes `$(SCENARIOS)` to `bench/run.sh`, whose default list names the scenarios when none is given.

## Goals / Non-Goals

Goals: the float, finder, and palette scenarios run by default and are gated by a budget that a doubled figure exceeds.

Non-goals: a time budget (machines differ), the `lh-winbar` and `n` scenarios, changing the `lh` maximum, a budget for `grep`.

## Decisions

- One `--budgets "NAME:MAX ..."` mode in `bench/run.sh` that calls the existing `--budget` branch per pair, rather than a shell loop in the Makefile, so the loop is a script a test can run over a fake program; it runs every pair and exits 1 if any failed, so one run names every exceeded scenario.
- The maxima are one make variable, `PICKER_BUDGETS`, a list of `name:max`, as `ALLOC_BUDGET` is one variable: lh-float 40, finder 600, palette 450, each about 1.6 times the figure at this commit and under 2 times, so a doubled figure fails and ordinary drift does not. They are objects, never time, as the existing budget.
- The three run at `BENCH_SMALL=20` and `BENCH_LARGE=120` since the finder's setup of 10,000 files dominates and the per-key figure does not change with the counts.
- `bench-budget` stays one target, so CI, `make check`, and the fast stages need no new stage.

## Risks / Trade-offs

- The finder adds about 25 seconds to `bench-budget` at `-O 0` (its setup runs twice); accepted, recorded in the findings file as a possible fixture reduction.
- A maximum 1.6 times the figure leaves room for a 60 percent regression to pass; the brief's bar is a doubled figure.
