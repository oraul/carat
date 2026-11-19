## ADDED Requirements

### Requirement: The message row has its own groups
The groups the message row draws SHALL have a row in every palette: `MsgDim` in the dim role, `ErrorMsg` in bold red, `WarningMsg` in yellow without bold, `MoreMsg` in bold blue, and `Question`.

#### Scenario: The groups in the carat themes
- **WHEN** `MsgDim`, `ErrorMsg`, `WarningMsg`, and `MoreMsg` are looked up in `carat-dark` and in `carat-light`
- **THEN** their foregrounds are the palette's dim, red, yellow, and blue, and `ErrorMsg` and `MoreMsg` are bold
