fix(pipeline): scout only the locations a change edits

## Summary

Scouts now read only the locations a change edits in each map area, and no scout starts for a change whose files lie in no map area. Scouts spent 40.5% of output and more than the implement phase at #140, and 18.7% to 32.1% at #134, #135, and #137, the last on a root LICENSE no map area places, because each scout read its whole area wide. The area plan now hands each scout the paths and lines it needs and is measured under its own key, so the scouts' recorded calls can be compared with the packs' own counts.

---

## Changes

- Change the Scout phase of the delivery workflow so the area plan lists, per needed area, the locations the change edits there, and a file in no map area belongs to no area.
- Add the pure helper scoutTargets, which starts no scout for an area given without a location, notes it, keeps the MAX_AREAS cut, and passes the locations into the scout's prompt.
- Change pack reuse so a pack is current only when its Locations line covers every location of the needed area, in the area-plan prompt and in scout.md step 3.
- Measure the area plan under its own key, areas, so phase.scout holds only the scouts' starts.
- Change the scout agent to read only the map lines, file locations, callers, and tests the locations need, a design only when the question asks, to copy the Rules line as written, and to record its tool calls in the pack header.
- Add tools_test cases for an area without locations, a plan of no area, the MAX_AREAS cut, the prompt's locations, the plan measured under areas, and pack currency.
- Document the narrower scout step in the README pipeline section.
- Record the planner's queue, the metrics row of ci-time-tidy-b, and six advisory findings in the backlog.

---

## Testing

- Run the security review of the committed diff, pass with no High, Medium, or Low finding.
- Run the checker's stages (docs-lint, dev-build, test-build, test-run, diagnose, bench-budget, metrics, tools-test, gates), all pass.
- Run the quality review, pass with no blocking finding after one fix round, and the benchmark review, pass.
- Run make spec-validate, 51 items pass.
- Run make docs-lint and make gates after packaging, both pass.

---

## Notes

The change alters only the delivery pipeline, which no spec describes, so it is archived with skip-specs. The acceptance figures (scouts under 15% of output and under the implement phase over three code changes) are measured on the next runs, not by this change. The quality review's six advisories, among them the area plan's tokens still keyed under the Scout phase by the token recorder and pack-currency cases that match prose, are recorded in the backlog for a follow-up.
