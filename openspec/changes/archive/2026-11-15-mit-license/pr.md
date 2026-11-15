docs: release carat under the mit license

## Summary

Releases carat under the MIT License with a root LICENSE file and a License section in the README that also credits the Spinel-derived files under tools/spinel/. The repository carried no license, so nobody could tell on what terms its code may be used, changed, or shared.

---

## Changes

- Add a root LICENSE file with the standard MIT License text and the copyright line for the carat authors, with no personal name, email address, or link
- Document the license in a new closing License section of README.md, crediting the header generated from Spinel and the generator modeled on Spinel's under tools/spinel/
- Record in docs/backlog.md that make types leaves build/carat.rbs behind and breaks every later compile, a finding the previous delivery reported without appending
- Record the two advisory findings of this change's quality review in docs/backlog.md, the next queue in docs/queue.md, and the merged changes' metrics row in docs/metrics.tsv
- Archive the OpenSpec change mit-license with skip_specs, since no editor behavior changes

---

## Testing

- Run the security review of the committed diff, passed with no High, Medium, or Low finding
- Run the checker's stages (docs-lint, dev-build, test-build, test-run, diagnose, bench-budget, metrics, tools-test, gates), all pass
- Run the quality review, passed with no blocking finding and two advisories recorded in the backlog
- Run the benchmark comparison against main's recorded figures, passed with no regression
- Run make spec-validate after archiving, 51 passed and 0 failed

---

## Notes

The two quality advisories are left for later items: the backlog entry this change added should use the file's Location and Fix outline wording, and Spinel's copyright and permission notice could be carried at the top of the tools/spinel/ files rather than only named in the README credit. The code map is unchanged because its checks cover only carat.rb and the five source roots, so a root LICENSE needs no area.
