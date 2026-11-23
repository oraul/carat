## MODIFIED Requirements

### Requirement: The slot shows the server's state
The `lsp` slot SHALL show the server's name and one dot after it, colored by the state: ready, starting or indexing (while a `$/progress` report runs), stopped, crashed, or untrusted. A crash SHALL add "crashed :LspRestart" after the dot and an untrusted directory "untrusted :LspStart". The slot's label SHALL keep the state's words and the percent SHALL show on the progress segment. The name SHALL be the server's reported name, or the command's first word.

#### Scenario: Indexing shows a percent
- **WHEN** the server reports progress begin and then 42 percent
- **THEN** the slot's label reads "ruby-lsp indexing 42%" and "ruby-lsp" after the progress ends, the bar drawing the dot in the starting color while the progress segment shows the percent

#### Scenario: A crash names the restart command
- **WHEN** the server's output ends without a shutdown
- **THEN** the slot's label reads "ruby-lsp crashed :LspRestart" and the bar draws the dot and the hint in the error group
