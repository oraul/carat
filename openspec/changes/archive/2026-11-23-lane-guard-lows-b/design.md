# Design

## Context

`wait` took the number from `refs/pull/*/head` on the pushed commit, then read it back with `gh` (`head_owned`) to refuse a fork's pull request. `gh` cannot run in the delivery environment, so the read-back never succeeded.

## Goals / Non-Goals

**Goals:**
- `wait` records the lone matching pull request without `gh`.
- The head repository and branch stay confirmed before a merge.

**Non-Goals:**
- Changing the merger, or the choice among several pull requests.

## Decisions

- Remove the read-back rather than make it optional: an optional check that is skipped when `gh` fails would be a guard that silently does nothing. The merger's step 1 reads the head repository and branch with the GitHub read tool and returns `stale` on a mismatch, so the guard lives in one place that can run.
- Known gap, recorded in the findings file: a fork's lone pull request can be recorded, and the recorded-number preference then keeps it after this repository's own pull request appears.
