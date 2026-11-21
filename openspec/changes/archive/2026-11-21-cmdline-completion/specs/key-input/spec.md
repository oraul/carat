## ADDED Requirements

### Requirement: Shift-Tab is its own key
The decoder SHALL turn `ESC [ Z` into the `<S-Tab>` key, which key notation SHALL read and write as `<S-Tab>`, and encode SHALL turn back into `ESC [ Z`.

#### Scenario: Shift-Tab decodes to its own key
- **WHEN** the bytes `ESC [ Z` arrive
- **THEN** the decoded key is `<S-Tab>`
