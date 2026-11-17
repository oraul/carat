## MODIFIED Requirements

### Requirement: git runs with no command from the repository's configuration
Every git command of the plugin SHALL run with lazy fetching off, with no transport allowed whatever the repository's configuration and the git version, and with the `ext::` transport and the fsmonitor hook refused on its command line, so that a partial clone whose promisor remote names a command, or whose configuration names an upload-pack program or an ssh command, runs no command, even under a trusted root and with a git that ignores `GIT_NO_LAZY_FETCH`.

#### Scenario: A promisor remote with a command runs nothing
- **WHEN** the working directory is under a trusted root, in a partial clone whose promisor remote is an `ext::` command and whose upstream commit is missing
- **THEN** the counts command runs with `GIT_NO_LAZY_FETCH=1`, `GIT_ALLOW_PROTOCOL` set to the empty string, `protocol.ext.allow=never`, and `core.fsmonitor=false`, the promisor's command never runs, and the segment shows the branch alone
