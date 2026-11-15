docs(ux-pass): record a three-view review of carat in use

## Summary

Records a three-view review of carat in use (Facet identity, other tools such as Neovim and VS Code, and a skeptic who must agree before a finding stays) over first use, empty and loading states, feedback, messages, floats, and key-to-answer time, with the release binary's screens as evidence. No review of how carat feels in use existed, and sprint 9's planning needs one to pick the UI work that puts a pleasant interface first.

---

## Changes

- Add the review to the archived change's design: the method, the screen list, the key-to-answer timing table, eleven kept findings with their reproductions and locations, nine findings the skeptic dropped with the reason, and what held up.
- Add 42 screen files under the archived change's screens directory, each a rendered 24 by 80 cell grid with its color runs, captured from the release binary driven in a pseudo-terminal, plus the key-to-answer times in timings.txt.
- Add the eleven kept findings to the end of the backlog, each with its location, its reproduction, and a fix outline, for sprint 9's planning.
- Add the five quality review advisories on the review's evidence and finding locations to the backlog.
- Change the queue to the planner's order and add the merged carat-palette-b row to the metrics history.

---

## Testing

- Run the security review of the committed diff, pass with no High, Medium, or Low finding.
- Run the checker's stages (docs-lint, dev-build, test-build, test-run, diagnose, bench-budget, metrics, tools-test, gates), all pass.
- Run the quality review, pass with no blocking finding and five advisories recorded in the backlog.
- Run the benchmark review, pass with no blocking finding.
- Run make spec-validate, make gates, and make docs-lint after the archive, all pass.

---

## Notes

No file under carat, bin, config, test, or tools changes, so the change sets skip_specs and the editor's behavior is unchanged. The pseudo-terminal driver and the canned language server lived in a scratch directory and are not committed, so the hover, completion, and starting states measure carat's side only; a later review with a real ruby-lsp can repeat them. Fixing the findings is left to sprint 9's planning.
