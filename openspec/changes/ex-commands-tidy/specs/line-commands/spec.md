## ADDED Requirements

### Requirement: A :normal refused as too deep ends every :normal running
Once a `:normal` is refused with "E192: Recursive use of :normal too deep", every `:normal` running SHALL stop, feeding none of its keys or lines left, so a binding that runs `:normal` over a range with its own key ends at once.

#### Scenario: Too deep stops the lines left
- **WHEN** ":%normal Q" is run on three long lines with Q bound to "x" and ":normal Q"
- **THEN** the message is "E192: Recursive use of :normal too deep", the first line is shortened, and the other two lines are unchanged

#### Scenario: A recursive normal over a range ends
- **WHEN** a key bound to ":%normal" with that same key is typed on two lines
- **THEN** the message is "E192: Recursive use of :normal too deep" and the lines are unchanged
