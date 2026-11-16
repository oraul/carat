## ADDED Requirements

### Requirement: The host runs a program only under a trusted root
The request `run_program` SHALL fail without starting anything while the editor's working directory is not a root of `language.trusted_roots` or below one, the same roots under which a language server starts on its own, and before the plugins are activated. The response SHALL say the program runs only under a trusted root.

#### Scenario: run_program outside a trusted root starts nothing
- **WHEN** the working directory is outside every root of `language.trusted_roots` and a plugin runs `git symbolic-ref --short -q HEAD`
- **THEN** the response fails naming `language.trusted_roots` and nothing is started

#### Scenario: run_program before activation starts nothing
- **WHEN** a plugin runs a program before the host activated the plugins
- **THEN** the response fails and nothing is started

### Requirement: The host runs a program with git's lazy fetch off
Every program the request starts SHALL have `GIT_NO_LAZY_FETCH=1` in its environment, besides the editor's own variables, so git never fetches a missing object from a promisor remote for a plugin.

#### Scenario: run_program turns lazy fetching off
- **WHEN** a plugin under a trusted root runs a program
- **THEN** the process port receives the variable `GIT_NO_LAZY_FETCH` set to `1`

#### Scenario: The driver adds the variables to the child environment
- **WHEN** the process runner captures a program with `GIT_NO_LAZY_FETCH` set to `1`
- **THEN** the program sees the variable set to `1`
