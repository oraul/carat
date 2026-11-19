chore(contributor): add a rules card and an edge-case checklist

## Summary

Adds a short rules card to the top of the contributor agent file and repeats it verbatim in every contributor start's prompt, with an edge-case checklist and a self-review of the diff against the quality reviewer's instructions. Quality fails its first pass on most runs from findings a checklist catches, and the contributor now runs on the mid tier, which forgets rules buried in a long agent file.

---

## Changes

- Add a ten-rule card at the top of the contributor agent file that holds the rules earlier runs broke
- Append the same card byte for byte to every contributor start's prompt in the delivery workflow
- Change the implement self-check to name the edge cases, a test per behavior change, the helper search, the comment, doc, and spec match, and the self-review
- Add docs/contributor-notes.md with the prose moved out of the agent file and the edge-case checklist, and place it in the code map
- Add tools-test cases that prove the card is identical in the agent file and in every mode's prompt and that the self-check names each point
- Document the card and the checklist in the README contributor step

---

## Testing

- Security review of the committed diff ran before packaging with no blocking finding
- Quality review ran with advisories only, each fixed or recorded in docs/findings/contributor-checklist.md
- Run the checker stages docs-lint, dev-build, test-build, test-run, diagnose, bench-budget, tools-test, and gates, all exit 0
- Run make spec-validate, 54 passed, 0 failed

---

## Notes

Tier routing for critical places and high effort for the mid tier are left to a follow-up change, contributor-tier-routing. Making rules 1, 2, and 7 mechanical is left to delivery-guards-b. No edit of tools/rules.sh and no budget was raised.
