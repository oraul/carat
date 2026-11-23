## ADDED Requirements

### Requirement: Bracketed paste is on while the editor runs
When the editor enters the screen it SHALL turn the terminal's bracketed paste on, and when it leaves the screen it SHALL turn it off before it resets the cursor shape and restores the main screen.

#### Scenario: Bracketed paste sequences
- **WHEN** the editor enters and then leaves the screen
- **THEN** the terminal output holds the bracketed paste enable sequence after the alternate-screen enable, and the disable sequence before the cursor shape reset
