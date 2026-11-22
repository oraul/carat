## ADDED Requirements

### Requirement: Tab completes a color scheme name
After `:colo[rscheme]` and blanks, `<Tab>` SHALL complete the word before the cursor from the shipped palette names it begins, in their shipped order, and `<S-Tab>` from the last, with the popup above the command line as for a path.

#### Scenario: Completing a palette name
- **WHEN** ":colorscheme one" then `<Tab>` are typed
- **THEN** the bottom row shows ":colorscheme one_dark" and the popup lists `one_dark` and `one_light`

#### Scenario: Every palette name
- **WHEN** ":colo " then `<Tab>` are typed
- **THEN** the popup lists every shipped palette name, `carat-dark` first, and the bottom row shows ":colo carat-dark"

#### Scenario: No palette name matches
- **WHEN** ":colorscheme zz" then `<Tab>` are typed
- **THEN** the bottom row still shows ":colorscheme zz" and the popup reads "No matches  Esc close"
