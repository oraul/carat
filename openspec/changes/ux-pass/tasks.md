# Tasks

## 1. Evidence

- [ ] 1.1 Build the release binary with `make build` and drive it in a pseudo-terminal as `test/smoke_editor.rb` does, with a scratch driver compiled by Spinel and never committed. Proven by the header of each screen file, which names its keys and times.
- [ ] 1.2 Save each topic's screens with their colors under `openspec/changes/ux-pass/screens/`, one text file per screen (first use, empty and loading states, feedback, messages, floats, time), and the key-to-answer times for a motion, an insert, and each float in `screens/timings.txt`. Proven by the files and `make gates` (the forbidden-text scan of the added lines).

## 2. Review

- [ ] 2.1 Record the three-view review of the six topics in `design.md`: the screen list, the timing table, each kept finding with its reproduction and location, and the skeptic's dropped findings with the reason. Proven by `make docs-lint` and `make spec-validate`.

## 3. Backlog

- [ ] 3.1 Append each kept finding to the end of `docs/backlog.md` with `>>`, as `### title` plus `- Location:`, `- Why:`, `- Fix:` lines, the reproduction in the Why line, without reading the file. Proven by `make docs-lint`.

## 4. Verify

- [ ] 4.1 Confirm no file under `carat/`, `bin/`, `config/`, `test/`, or `tools/` changed (`git diff --stat main`), then run `make lint`, `make docs-lint`, `make gates`, and `make spec-validate`.
