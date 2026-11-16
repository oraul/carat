# git-status Specification

## Purpose
Show the git branch of the editor's working directory with its ahead and behind counts in the status bar through the git_signs plugin, silent outside a repository or without git, and treating git's output as untrusted text.

## Requirements

### Requirement: The status bar shows the git branch with its counts
The `git_signs` plugin SHALL show, as its status bar segment at priority 40, the `git` icon, a space, and the current branch of the editor's working directory, then the `ahead` icon and the commits its upstream lacks, and the `behind` icon and the commits it lacks from its upstream, each only when above zero. The counts SHALL follow the branch, each one space after what precedes it.

#### Scenario: The branch and both counts show
- **WHEN** git answers the branch "main", one commit ahead of its upstream and two behind, with the unicode icons
- **THEN** the plugin's segment reads "± main ↑1 ↓2" and the status bar shows it

#### Scenario: A branch without an upstream shows alone
- **WHEN** git answers the branch "topic" and nothing for the counts
- **THEN** the segment reads "± topic"

#### Scenario: The segment under ascii icons
- **WHEN** the same branch and counts are shown with `option.icons ascii`
- **THEN** the segment reads "g main +1 -2", every character ASCII

### Requirement: The branch segment refreshes on open, save, and focus
The plugin SHALL refresh its segment when it is activated, when a buffer opens or is saved, and when a window gains the focus.

#### Scenario: The segment follows a branch change on save
- **WHEN** git answers another branch and a buffer is saved
- **THEN** the segment shows the new branch

#### Scenario: The segment follows a branch change on focus
- **WHEN** git answers another branch and the focus moves to another window
- **THEN** the segment shows the new branch

#### Scenario: The segment shows on activation
- **WHEN** git answers a branch and the plugin is activated, before any buffer opens
- **THEN** the segment shows the branch

### Requirement: No branch shows without a repository or without git
Outside a git repository, on a detached head, or when git cannot run, the plugin SHALL show no segment and no message, and no error SHALL reach the editor.

#### Scenario: Outside a repository nothing shows
- **WHEN** git runs but prints no branch
- **THEN** the plugin has no segment and the message row is empty

#### Scenario: Without git nothing shows
- **WHEN** no git program can start
- **THEN** the plugin has no segment, the message row is empty, and the plugin stays enabled

### Requirement: git's output is untrusted text
The plugin SHALL read only the first line of git's answer for the branch, drop its control characters, and cut it to 60 characters, and SHALL read a count that is not one to nine digits as zero.

#### Scenario: Control characters in the branch are dropped
- **WHEN** git answers a branch name holding an escape character and a tab
- **THEN** the segment holds the name without them

#### Scenario: A count that is not digits reads as zero
- **WHEN** git answers "x\t2" for the counts
- **THEN** the segment shows no ahead count and the behind count 2

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
