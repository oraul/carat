# Design

## Context

`tools/docs_lint.sh` holds `CLAUDE.md` to 30,720 bytes and `docs/architecture.md` to 88,064. Both are at their limit (38 and 10 bytes left at d386c74). The queue item accepts the change when each has at least 1,000 bytes free, `CLAUDE.md` at most 27,648, no rule changed in meaning, section 5.1 complete, and the two Git rules restored.

## Goals / Non-Goals

Goals: room in both documents by moving reference detail to where it already lives; the drifts the reviews found in them fixed. Non-goals: rewording rules, changing a budget, documenting new behavior.

## Decisions

- Where `CLAUDE.md`'s bytes come from: the Commands section (3,193 bytes). Its bullets repeat what `make help` prints for each target (the output paths, the variables and their defaults, the stage list) and what the header of `tools/run_state.sh` documents for each command. The section keeps the claim that it names every target, so each target keeps its name, and keeps every sentence that is a rule (the pin bumped in its own pull request after `make check`, `make diagnose` clean, a test without a snapshot failing, never `spin test`, `make clean` never touching `tmp/`). Alternative: trimming the Coding conventions (7,398 bytes); rejected, since nearly every sentence there is a rule `lint` or a reviewer enforces.
- The `run_state.sh` bullet keeps the commands an agent acts on from `CLAUDE.md` (`check`, `push`, `backup`, `restore`, `abandon`, `history`, `status`) in a few words each and points to the header for the rest. `restore` is described as the header says: it creates the branch from `refs/backup/BRANCH` when the branch exists neither here nor on origin; the resume step checks it out.
- Where `docs/architecture.md`'s bytes come from: section 11 lists every file of the domain, use case, port, adapter, driver, and double directories, a list `docs/codebase-map.md` keeps complete under `lint`'s coverage check while section 11's copy has already drifted. Section 11 keeps the tree of directories and top-level files, with each layer's line pointing to the map. Alternative: shortening section 10 (8,445 bytes), which states testing rules; rejected.
- Section 5.1 and 5.3: the missing names are those of the plain use case classes under `carat/use_cases/` that no section names: `SubstituteLines` (named as `Substitute`), `DeleteLines`, `OpenSearchPrompt`, `PreviewSearch`, `RecallHistory`, and `ScrollWindow`. Handlers, requests, and the plugin host stay out of the lists, as section 5 says.

## Risks / Trade-offs

- A reader of `CLAUDE.md` runs `make help` or opens the script's header for a target's variables: one more step, which every agent already takes for the details it needs.
- Section 11 no longer lists files, so a file moved between layers is checked by the map's coverage rule only, which `lint` enforces.
