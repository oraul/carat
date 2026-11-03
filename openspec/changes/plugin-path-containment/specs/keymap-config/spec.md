# Spec Delta

## ADDED Requirements

### Requirement: A binding of more than 64 keys is reported and skipped
A keymap line whose key notation reads as more than 64 keys SHALL be reported as `file:line: more than 64 keys` and skipped, in any configuration file and in a plugin's default bindings, while every other line still loads. A binding of exactly 64 keys SHALL still be bound, and removing a plugin's bindings SHALL never fail on a long binding.

#### Scenario: A binding one key too long
- **WHEN** the project file's first line binds a sequence of 65 "j" keys in normal mode to "cursor.down"
- **THEN** ".caratrc:1: more than 64 keys" is reported and the sequence is not bound

#### Scenario: A binding at the limit
- **WHEN** the project file's first line binds a sequence of 64 "j" keys in normal mode to "cursor.down"
- **THEN** nothing is reported and the 64 keys are bound to "cursor.down"

#### Scenario: A plugin's long binding
- **WHEN** a plugin's default bindings hold a line of 65 keys and a line of 64, and the plugin's bindings are then removed
- **THEN** the long line is recorded as an error of the plugin's bindings and is not bound, and the removal drops the 64-key binding
