# Proposal

## Why

`groom` (`tools/run_state.sh`) keeps a security entry in the backlog unless a merged item listed it or a commit of the sprint fixed it, but it judges an entry security only by `SECURITY_MARK`, which the groom-proof change narrowed to a severity word right after "security" (`security Low`) or a severity and confidence pair (`High (8)`). A security entry worded otherwise, such as one marked only "Low finding of the periodic security review", passes `closed`, `gone`, `duplicate`, or a merge into a non-security entry, so it can leave unfixed: the sprint-18 periodic security review's Medium (9), which stopped sprint-18-records. The same check is written four times, one per kind. A merged entry's body is also sent through a text channel whose marker lines start with `@@kept `, so a body line of that form redirects the rest of the body to another heading, and drops it when that heading does not stand (Low (3)). The brief is `brief.md`; outside the roadmap of `docs/architecture.md` section 12, a pipeline defect (T0 security).

## What Changes

- An entry is a security entry when its text names security, as a word, and a severity (`critical`, `high`, `medium`, `low`, or `disputed`, a plural included) anywhere in it, in either order and across its lines, or carries a severity and confidence pair such as `High (8)`, any case; so "Low finding of the periodic security review" is one, and a text that names security with no severity, such as the quoted "Security first" section title, is still not.
- The judgement is one function, `security_entry`, and one guard before the kinds' proofs: `closed`, `gone`, and `duplicate` refuse a security entry, and `merged` refuses one whose kept heading is not a security entry; the four repeated checks go.
- A merged entry's lines reach the backlog rewrite through a channel where each kept heading and each body line carries its own prefix, so no body text can redirect or drop the rest: a body line `@@kept X` stays under the kept heading, in place.
- `tools/tools_test.sh`: the groom fixture gains an entry marked only "Low finding of the periodic security review" and an entry with a body line `@@kept ## y quality advisory`; new cases refuse `closed`, `gone`, `duplicate`, and a merge into a plain entry for the first, and the sprint apply merges the second, keeping its `@@kept` line and the lines after it under the kept heading and adding nothing to `## y quality advisory`.

Out of scope: `tools/rules.sh` is not edited; backlog-pick's own security ranking (any entry naming security, wider on purpose) is unchanged; no file of the feature lane is touched; `build/plan` is not applied; no backlog entry is removed by this change.

Assumption (minor): judging security by the whole entry rather than one line keeps more entries than strictly needed (an entry naming security in one line and a low risk in another), which errs toward keeping a security entry; such an entry still leaves by `listed` or `fixed`.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

None: the delivery pipeline is described by no spec under `openspec/specs/` (`skip_specs: true`).

## Impact

- `tools/run_state.sh` (`SECURITY_MARK`, a new `security_entry`, `groom`, its header comment), `tools/tools_test.sh`.
- README.md: changed, the security entry's wording in the grooming sentence of pipeline step 11.
- docs/codebase-map.md: changed, the `groom` description of `tools/run_state.sh`; no file is added, moved, or removed.
- CLAUDE.md: unchanged, its Backlog line (a security entry leaving only listed or fixed) still holds and names no wording.
- docs/architecture.md: unchanged, it does not describe groom.
