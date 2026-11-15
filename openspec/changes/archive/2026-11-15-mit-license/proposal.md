# Proposal

## Why

carat carries no license, so nobody can tell on what terms its code may be used, changed, or shared. The user asked for the MIT License (sprint 7's head item in `docs/queue.md`, tier T2, a user request). `tools/spinel/` also holds a header generated from Spinel and a generator modeled on Spinel's, which the repository credits nowhere.

## What Changes

- A root `LICENSE` file with the standard MIT License text and the copyright line `Copyright (c) 2026 The carat authors`: no personal name, no email address, no link.
- A `## License` section at the end of `README.md`: one sentence that carat is released under the MIT License (see `LICENSE`), and one line crediting `tools/spinel/`, a header generated from Spinel (MIT, by Yukihiro Matsumoto) and a generator modeled on Spinel's.
- One entry appended with `>>` to the end of `docs/backlog.md`, which the previous delivery's contributor reported and did not append: `make types` leaving `build/carat.rbs`, which breaks every later compile.

No editor behavior changes, so `skip_specs` is set.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

None. No behavior changes.

## Impact

- `LICENSE` (new, at the root).
- `README.md`: the new `## License` section.
- `docs/backlog.md`: one appended entry.
- `docs/codebase-map.md`: unchanged, its lint check (`test/lint.rb` `map_files`) and the docs gate (`tools/gates.sh` `gate_docs`) cover `carat.rb` and the five roots only, so a root `LICENSE` needs no area.
- CLAUDE.md: unchanged, no command, agent, workflow, or rule changes.
- docs/architecture.md: unchanged, no layer, port, or design changes.

Outside the roadmap of `docs/architecture.md` section 12: a licensing record the user asked for.

## Out of scope

- License headers in source files, a NOTICE file, or a license field anywhere else.
- Any change to `tools/spinel/` itself, or to the Makefile `types` target the backlog entry describes (that fix is a later item).
- Naming `LICENSE` in the prose list of root files in area 1 of the map, which no check requires and the brief asks only if one does.

Assumptions recorded here instead of asked: the section is the README's last, after `## How carat is built with AI`, where a license section usually sits; the credit names Spinel's license and author as the brief gives them, since the repository holds no copy of Spinel's license to quote.
