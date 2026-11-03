# Spec Delta

## ADDED Requirements

### Requirement: A rename or delete request never goes through a link that leaves the root
The host SHALL refuse a rename or delete request with `Outside the tree root: path` and no change on disk when the directory holding the entry, with every symbolic link resolved, is neither the root with its links resolved nor inside it. A link that resolves inside the root, a root that is itself a link, and a link entry itself, which is renamed or removed and never followed, SHALL still work.

#### Scenario: Rename below a link leading outside
- **WHEN** "/w/out" is a symbolic link to "/elsewhere", which holds "x.rb", and a plugin renames "/w/out/x.rb" to "y.rb" under the root "/w"
- **THEN** the response is failed with "Outside the tree root: out/x.rb" and "/elsewhere/x.rb" still exists

#### Scenario: Delete below a link leading outside
- **WHEN** "/w/out" is a symbolic link to "/elsewhere", which holds "x.rb", and a plugin deletes "/w/out/x.rb" under the root "/w"
- **THEN** the response is failed with "Outside the tree root: out/x.rb" and "/elsewhere/x.rb" still exists

#### Scenario: Rename and delete below a link staying inside
- **WHEN** "/w/alias" is a symbolic link to "/w/lib", and a plugin renames "/w/alias/x.rb" to "y.rb" and then deletes "/w/alias/y.rb" under the root "/w"
- **THEN** both responses succeeded

#### Scenario: Linked root
- **WHEN** the root "/r" is itself a symbolic link to "/real" and a plugin renames "/r/a.rb" to "b.rb" and deletes "/r/b.rb"
- **THEN** both responses succeeded

#### Scenario: The link itself
- **WHEN** "/w/out" is a symbolic link to "/elsewhere" and a plugin renames it to "away" under the root "/w"
- **THEN** the response succeeded and "/elsewhere" and its entries are unchanged
