## ADDED Requirements

### Requirement: The visual mode indicators are dim
The message row's visual mode indicators, `-- VISUAL --`, `-- VISUAL LINE --`, and `-- VISUAL BLOCK --`, SHALL be drawn in the `MsgDim` group, as the pending keys beside them are, in every theme and under `NO_COLOR`.

#### Scenario: The visual indicators are dim
- **WHEN** the mode is charwise, linewise, or blockwise visual with an empty message
- **THEN** every cell of the indicator on the message row is in `MsgDim`
