# Design

## Context

`calibrate(kind, opts)` takes a kind's profile from `CALIBRATION` and passes its effort unless it is `session`.

## Decisions

- `calibrate` picks `session/session` for the contributor when `criticalRule()` (the plan's letter, or `e` for a large estimate) or `escalated` holds; the one table row stays `agent/high`.
- The plan carries `critical` as optional text `LETTER PATH`, read by one pattern; anything else is no critical rule.
- `escalate(why)` runs once, never in a critical run, and queues an `escalation` note; the three triggers sit where the workflow already sees them (the contributor loop, the quality verdict).
- The metric line stores `critical=LETTER` and `escalated=1`; a restart restores both.
- No delta specs: `skip_specs: true`, archived with `--skip-specs`.

## Risks

A mid-tier start may omit `self_check`; the other two triggers still apply.
