## ADDED Requirements

### Requirement: A create never follows a link planted after its checks
A file a plugin or the explorer creates SHALL be made only as a new regular file at the path itself. When a symbolic link appears at the path after the checks found nothing there, the create SHALL fail with a failed response, write nothing through the link, and leave the link's target unchanged.

#### Scenario: A link planted at the target after the checks
- **WHEN** a plugin creates "tree/new.rb" under the root "tree" and a symbolic link to a file outside the tree appears at "tree/new.rb" after the checks passed
- **THEN** the response is failed and the outside file keeps its text
