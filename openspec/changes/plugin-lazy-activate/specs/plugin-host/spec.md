## ADDED Requirements

### Requirement: A plugin activates on its first trigger
The host SHALL read an enabled plugin's manifest at startup, resolving its options and merging its default bindings, without activating it. It SHALL activate the plugin, once, on its first trigger: the first run of an action it declares, from a key bound to it or otherwise; the first ex command it declares; or the first time a buffer of a filetype it declares is highlighted.

#### Scenario: No plugin is active at startup
- **WHEN** the editor starts on a ruby file with the explorer, finder, ruby, and git_signs plugins enabled and draws its first frame
- **THEN** none of them is active, and the explorer, finder, and ruby plugins are still not active after the editor goes idle

#### Scenario: The explorer activates on its key
- **WHEN** the editor has started and the explorer's key is pressed
- **THEN** the explorer is active and its window opens as before

#### Scenario: The explorer activates on its ex command
- **WHEN** the editor has started and ":Explorer" is run
- **THEN** the explorer is active and its window opens

#### Scenario: The finder activates on its key
- **WHEN** the editor has started and the finder's key is pressed
- **THEN** the finder is active and its float opens

#### Scenario: The ruby plugin activates on its first ruby buffer
- **WHEN** the editor starts on a text file and then ":e" opens a ruby file
- **THEN** the ruby plugin is not active before the ruby buffer is drawn and is active, its lines highlighted, after

#### Scenario: A raise in a late activate
- **WHEN** a test plugin raises in its activate and the key bound to its action is pressed, then "x" is pressed
- **THEN** the message row reads "Plugin <name> disabled: <error>", the action did not run, and "x" deletes the character

### Requirement: A plugin with no trigger activates when the editor is first idle
A plugin that declares no action, ex command, or filetype SHALL be activated when the editor is first idle after the first frame is drawn, and never before that frame.

#### Scenario: Git runs only after the first frame
- **WHEN** the editor starts on a file in a repository under a trusted root
- **THEN** no git command has run when the first frame is drawn, and once the editor is idle git_signs is active and the branch segment shows

### Requirement: Events reach only an active plugin
Events SHALL reach a plugin only once it is active; what happened before, the plugin reads in its activate. Only an active plugin SHALL be deactivated when the editor ends.

#### Scenario: Events wait for activation
- **WHEN** a plugin with an action, subscribed to every event, is not yet active and a file is opened, then its action runs
- **THEN** it received no event before its activate, and receives the events of later keys

## MODIFIED Requirements

### Requirement: A plugin can run ex commands while activating
A plugin SHALL be able to run an ex command string from its activation, at its first trigger, with the same outcome as later.

#### Scenario: Tab page in activate
- **WHEN** a test plugin runs "tabnew" while activating and the key bound to its action is pressed
- **THEN** the run succeeded and the editor has two tab pages
