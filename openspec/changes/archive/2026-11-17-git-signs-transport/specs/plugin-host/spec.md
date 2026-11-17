## ADDED Requirements

### Requirement: The host runs a program with every git transport refused
Every program the `run_program` request starts SHALL have `GIT_ALLOW_PROTOCOL` set to the empty string in its environment, beside `GIT_NO_LAZY_FETCH=1`, so a git it runs allows no transport, whatever the repository's configuration says and also with a git older than 2.44, which ignores `GIT_NO_LAZY_FETCH`, and a fetch, lazy or not, reaches no remote and starts no command.

#### Scenario: run_program allows no transport
- **WHEN** a plugin under a trusted root runs a program
- **THEN** the process port receives `GIT_NO_LAZY_FETCH` set to `1` and `GIT_ALLOW_PROTOCOL` set to the empty string

#### Scenario: The driver adds an empty variable to the child environment
- **WHEN** the process runner captures a program with `GIT_ALLOW_PROTOCOL` set to the empty string
- **THEN** the program sees the variable set, and empty

### Requirement: A disabled plugin's floats close
When a plugin is disabled, the host SHALL close every float the plugin opened, in every tab page, and leave the floats of other plugins and of the editor open.

#### Scenario: Disabled with floats in two tab pages
- **WHEN** a test plugin with a float in tab page 1 and a float in tab page 2, beside another plugin's float, raises in an action
- **THEN** neither tab page holds a float of the plugin and the other plugin's float is still open
