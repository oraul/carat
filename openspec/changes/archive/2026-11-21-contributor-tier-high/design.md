# Design

## Context

`calibrate(kind, opts)` reads a kind's `TIER/EFFORT` from `CALIBRATION`, passes the effort unless it is `session`, and gives the contributor the session's profile (`model: 'inherit'`, no effort) when the run is critical or escalated. `PROFILE` is the one pattern of a profile's form, read by the metric line, the restart restore, and tools-test.

## Decisions

- One table value changes, the contributor's, from `agent/medium` to `agent/high`; the routing code stays as it is, so a critical, large-estimate, or escalated start still takes `session/session`.
- `PROFILE` keeps `medium`, so the rows recorded at medium are still read and restored, and a later move may use it again; tools-test's restart case keeps a medium profile.
- The trial's end is written in `docs/goals.md`, Calibration, as a line of its own after the trial's, with the two runs' figures the brief gives; the trial line itself is left as the record of what was tried.
- No delta specs: `skip_specs: true`, archived with `--skip-specs`.

## Risks

High effort costs more tokens per run than medium (the high-effort rows #233 to #250 averaged 2.10M weighted); the user's decision accepts that for the procedural steps it keeps.
