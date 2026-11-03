# Spec Delta

## ADDED Requirements

### Requirement: A create request never goes through a link that leaves the root
The host SHALL refuse a create request, a file or a directory, with `Outside the tree root: path` and no change on disk, when the parent directory of the path, with every symbolic link resolved, is neither the root with its links resolved nor inside it. A link inside the root that resolves inside it SHALL still be created through.

#### Scenario: Linked parent leading outside
- **WHEN** "/w/out" is a symbolic link to "/elsewhere" and a plugin creates "/w/out/x.rb" under the root "/w"
- **THEN** the response is failed with "Outside the tree root: out/x.rb" and "/elsewhere/x.rb" does not exist

#### Scenario: Linked parent staying inside
- **WHEN** "/w/alias" is a symbolic link to "/w/lib" and a plugin creates "/w/alias/x.rb" under the root "/w"
- **THEN** the response succeeded and "/w/lib/x.rb" exists

#### Scenario: Linked root
- **WHEN** the root "/w" is itself a symbolic link to "/real" and a plugin creates "/w/new.rb"
- **THEN** the response succeeded
