## REMOVED Requirements

### Requirement: Unimplemented actions report themselves
**Reason**: Search was the last action the default configuration bound without implementing it, so no key of the default configuration answers "Not implemented" any more.
**Migration**: None; the dispatcher still answers "Not implemented: " followed by the name for an action no handler takes, and `/` now opens the search prompt of the `search` capability.
