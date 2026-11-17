## ADDED Requirements

### Requirement: A plugin focuses only its own floats
Focusing a float the plugin did not open, another plugin's or the editor's completion popup, SHALL fail with "No window N", N the id asked for, and change nothing, as moving or closing it fails; focusing window 0 SHALL still answer the current window and change nothing.

#### Scenario: Focus another plugin's float
- **WHEN** a plugin focuses the id of a float another plugin opened
- **THEN** the response is failed with "No window N" and the current window is unchanged
