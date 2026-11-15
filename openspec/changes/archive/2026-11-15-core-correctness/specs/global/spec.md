# Spec Delta

## ADDED Requirements

### Requirement: A reverted edit keeps the marks on their lines
When an edit made inside a running global is undone before the global ends, as the plugin host does with an edit request that fails part way, the marked lines SHALL keep their marks on the lines they marked before the edit.

#### Scenario: A reverted plugin edit inside a global
- **WHEN** lines 0, 2, and 3 are marked, line 0 is visited, and an edit that inserts two lines above line 2 is reverted
- **THEN** the lines visited next are 2 and 3
