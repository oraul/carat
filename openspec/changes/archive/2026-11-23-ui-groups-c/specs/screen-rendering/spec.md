## REMOVED Requirements

### Requirement: The visual mode indicators are dim
**Reason**: Neovim draws its mode message in `ModeMsg`, a group a theme sets and nothing drew; the indicators move to it.
**Migration**: The requirement "The visual mode indicators are in ModeMsg" replaces it.

## ADDED Requirements

### Requirement: The visual mode indicators are in ModeMsg
The message row's visual mode indicators, `-- VISUAL --`, `-- VISUAL LINE --`, and `-- VISUAL BLOCK --`, SHALL be drawn in the `ModeMsg` group, as Neovim draws its mode message, and the pending keys beside them in `MsgDim`, in every theme and under `NO_COLOR`.

#### Scenario: The visual indicators are in ModeMsg
- **WHEN** the mode is charwise, linewise, or blockwise visual with an empty message
- **THEN** every cell of the indicator on the message row is in `ModeMsg`
