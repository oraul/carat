## ADDED Requirements

### Requirement: The branch segment needs a trusted root
The plugin SHALL run no git and show no segment and no message while the editor's working directory is outside the roots of `language.trusted_roots`, since a repository's configuration can name a command git runs.

#### Scenario: Outside a trusted root no git runs
- **WHEN** the working directory is in a repository outside every root of `language.trusted_roots` and a buffer opens
- **THEN** no git command starts, the plugin has no segment, and the message row is empty

#### Scenario: Under a trusted root the branch and counts show
- **WHEN** the working directory is under a root of `language.trusted_roots` and git answers the branch "main", one commit ahead and two behind
- **THEN** the segment reads "± main ↑1 ↓2"

### Requirement: git runs with no command from the repository's configuration
Every git command of the plugin SHALL run with lazy fetching off and with the `ext::` transport and the fsmonitor hook refused on its command line, so that a partial clone whose promisor remote names a command runs no command, even under a trusted root.

#### Scenario: A promisor remote with a command runs nothing
- **WHEN** the working directory is under a trusted root, in a partial clone whose promisor remote is an `ext::` command and whose upstream commit is missing
- **THEN** the counts command runs with `GIT_NO_LAZY_FETCH=1`, `protocol.ext.allow=never`, and `core.fsmonitor=false`, the promisor's command never runs, and the segment shows the branch alone
