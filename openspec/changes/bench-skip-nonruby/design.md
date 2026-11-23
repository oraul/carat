# Design

## Context

The Benchmark phase runs whenever the bench review is not recorded at the head: it records at once when the check measured main's figures as equal, else it starts the benchmark agent. Neither needs to run for a diff that changes no Ruby code.

## Goals / Non-Goals

**Goals:**
- A diff with no Ruby code records the bench review passed at the head with no agent start.
- Every other diff keeps the gate unchanged, and the merge gates read the same record.

**Non-Goals:**
- A tolerance or rerun for allocation noise in Ruby changes.
- Any edit of `tools/rules.sh` or of what the check's stages run.

## Decisions

- The decision comes from git: `tools/lane_facts.sh` prints `ruby yes|no|unknown` beside `machinery`, computed from the same `git diff --name-only` of the merge base to HEAD. A path git quotes keeps its leading quote in the pattern, so it reads `yes`, never outside the Ruby code.
- The workflow has no shell, so `benchWithoutRuby` reads the fact with `laneHead`, the record start `machinery` already uses. `parseLaneFacts` keeps only `yes` or `no`; `noRubyAt` holds only for `ruby no`, a lane with no uncommitted path (`dirty 0`), and a lane head equal to the workflow's head, and `benchWithoutRuby` also needs the check recorded at the head. A forged or malformed line, a dirty or unread lane, or another head keeps the gate.
- The branch stands after the equal-figures branch, so a change whose figures equal main's costs no extra start, and before the agent. The record is the same three calls as the equal-figures branch (`verdict`, a note, `reviewed` with zero blocking), so `review.bench` is `pass HEAD` for the merge gates.
- The paths are the brief's: `carat/`, `bin/`, `bench/`, `config/`, `carat.rb`. A `Makefile` or `tools/spinel/` change (a Spinel bump) is not Ruby code here; CI's metrics stage still compares it, and the finding is recorded.

## Risks / Trade-offs

- A relayed `ruby no` is as trustworthy as the relayed `machinery no`; it is strictly parsed and only skips a comparison CI repeats.
