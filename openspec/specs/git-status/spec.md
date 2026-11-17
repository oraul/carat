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
The plugin SHALL refresh its segment when it is activated, when a buffer opens or is saved, and when a window gains the focus, a focus with the working directory's `.git` state unchanged keeping the segment without running git.

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
Every git command of the plugin SHALL run with lazy fetching off, with no transport allowed whatever the repository's configuration and the git version, and with the `ext::` transport and the fsmonitor hook refused on its command line, so that a partial clone whose promisor remote names a command, or whose configuration names an upload-pack program or an ssh command, runs no command, even under a trusted root and with a git that ignores `GIT_NO_LAZY_FETCH`.

#### Scenario: A promisor remote with a command runs nothing
- **WHEN** the working directory is under a trusted root, in a partial clone whose promisor remote is an `ext::` command and whose upstream commit is missing
- **THEN** the counts command runs with `GIT_NO_LAZY_FETCH=1`, `GIT_ALLOW_PROTOCOL` set to the empty string, `protocol.ext.allow=never`, and `core.fsmonitor=false`, the promisor's command never runs, and the segment shows the branch alone

### Requirement: Signs mark the lines that differ from HEAD
Under a trusted root, the `git_signs` plugin SHALL place on a buffer whose file is below the editor's working directory the `git_added` icon on each line added since HEAD, the `git_changed` icon on each line of a run that replaced lines, and the `git_deleted` icon on the line above a run of removed lines, or on the first line when the run was at the top.

#### Scenario: Each sign kind shows on its lines
- **WHEN** git holds "one two three four five" at HEAD, one word a line, and the buffer reads "one TWO three new four"
- **THEN** the second line has the `git_changed` sign, the fourth the `git_added` sign, the fifth the `git_deleted` sign, and the first and third none

#### Scenario: Lines removed at the top mark the first line
- **WHEN** git holds "zero one two" at HEAD and the buffer reads "one two"
- **THEN** the first line has the `git_deleted` sign and the second none

### Requirement: The signs follow the buffer's text
The signs SHALL compare the buffer's text, unsaved edits included, and SHALL be placed again when the plugin is activated, when the buffer opens or is saved, and when a window showing it gains the focus.

#### Scenario: The signs follow an unsaved edit on focus
- **WHEN** a line is added to the buffer and the focus moves to another window and back
- **THEN** the added line has the `git_added` sign

### Requirement: No sign shows without text at HEAD
A file git does not hold at HEAD, a file empty at HEAD, a file whose text at HEAD is longer than a capture keeps, and a buffer with no file SHALL show no sign of the plugin.

#### Scenario: A file git does not hold shows no sign
- **WHEN** git answers nothing for the file's text at HEAD
- **THEN** the buffer has no sign of the plugin

### Requirement: The text at HEAD is read with no command from the repository's configuration
The plugin SHALL read a file's text at HEAD with `git cat-file blob HEAD:./PATH`, PATH relative to the working directory, carrying the same `protocol.ext.allow=never` and `core.fsmonitor=false` arguments as the branch command, and SHALL compare it with the buffer itself, so that git never reads the work tree.

#### Scenario: The text capture refuses ext:: and fsmonitor
- **WHEN** a buffer opens under a trusted root in a repository
- **THEN** git is asked for the branch, the counts, then `git -c protocol.ext.allow=never -c core.fsmonitor=false cat-file blob HEAD:./a.txt`, each with `GIT_NO_LAZY_FETCH=1`

### Requirement: A focus with HEAD unchanged runs no git
When the working directory holds a `.git` directory whose `HEAD`, branch ref, `packed-refs`, and `logs/HEAD` read the same as at the plugin's last git run, a window gaining the focus SHALL run no git: the segment SHALL stay and the buffer's signs SHALL be placed from the text at HEAD the plugin already read for it. When any of those changed, or the working directory holds no `.git` directory, a focus SHALL ask git as an open does.

#### Scenario: A focus with HEAD and the file unchanged runs no git
- **WHEN** a buffer opened in a repository and the focus moves to another window and back, `.git` unchanged
- **THEN** no git command runs after the open and the signs stay

#### Scenario: A focus after HEAD moved asks git again
- **WHEN** the branch's ref file changes and the focus moves
- **THEN** git is asked for the branch, the counts, and the text at HEAD again

### Requirement: A renamed buffer reads its new path at HEAD
The text at HEAD the plugin keeps for a buffer SHALL belong to the buffer's path when it was read: after an open buffer's path changes, as a rename of its file does, the next focus or save SHALL ask git for the text at HEAD of the new path, even with `.git` unchanged, and the signs SHALL compare with that text.

#### Scenario: A renamed buffer asks git for its new path
- **WHEN** an open buffer's file is renamed, `.git` unchanged, and the focus moves
- **THEN** git is asked for the branch, the counts, and the text at HEAD of the new path, and the signs compare with that text

### Requirement: A timed-out git command stalls no later event
After a git command of the plugin runs past the host's deadline, the plugin SHALL run no git on any later event until the working directory's `.git` state reads differently, and SHALL keep its segment and signs as they were.

#### Scenario: A timed-out capture stalls no later event
- **WHEN** the branch command runs past the deadline on a buffer open, then a save, a focus change, and another open follow
- **THEN** no git command runs after the one that timed out

#### Scenario: git runs again after HEAD moves
- **WHEN** a command timed out and then the branch's ref file changes and a buffer opens
- **THEN** git is asked for the branch again
