## ADDED Requirements

### Requirement: The scope guide is solid
The guides of the cursor's block, drawn in `IblScope`, SHALL be a solid `│`, and every other guide the guide character; with `option.icons ascii` the cursor's block guides SHALL be drawn as `|`.

#### Scenario: The scope guide is solid
- **WHEN** the cursor is in a nested block with the shipped guide character
- **THEN** the guides of the cursor's block are `│` and every other guide is `┊`

#### Scenario: The scope guide in ASCII
- **WHEN** `option.icons ascii` is set and the cursor is in a nested block
- **THEN** the guides of the cursor's block are `|`
