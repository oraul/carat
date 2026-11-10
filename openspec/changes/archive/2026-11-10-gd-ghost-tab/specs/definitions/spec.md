## MODIFIED Requirements

### Requirement: Targets outside the project open read-only
A target SHALL open through the file-open refusals (a directory, a non-regular file, a file over the limit). A target outside the working directory, or whose path leaves it through a link, SHALL open as a listed, read-only file buffer named with its path as `:e` would name it, which `:w` refuses. A target in a file outside the project that is already listed SHALL show that buffer, with its unsaved text, and list no second buffer.

#### Scenario: A target outside the project opens read-only
- **WHEN** the answer is one location in a file outside the working directory
- **THEN** a read-only buffer named with its path is current, on the target line, and `:w` and `:wa` are refused with E45 and leave the file as it was

#### Scenario: A target that is not a regular file is refused
- **WHEN** the answer is one location whose path is a directory
- **THEN** the message row reads the directory refusal and the buffer stays

## ADDED Requirements

### Requirement: The definition target has a tab
The buffer a `gd` jump shows SHALL have a tab in the tab row like any file buffer's, wherever its file lies: shown, selected while it is current, reached by `:bn`, `:bp`, and `:b N`, and closed by `:bd`.

#### Scenario: gd to another project file shows its tab, selected
- **WHEN** the answer is one location in `/project/b.rb`
- **THEN** `b.rb` is current and its tab is the selected one

#### Scenario: gd outside the project shows the target's tab, selected
- **WHEN** the editor is on `a.rb` and the answer is one location in `/gems/c.rb`
- **THEN** row 0 is the tab row with a tab for `a.rb` and one for `c.rb`, the `c.rb` tab selected, and two buffers are listed

#### Scenario: gd to a project file linked out of the project shows its tab, selected
- **WHEN** `/project/out.rb` is a link to `/gems/c.rb` and the answer is one location in `/project/out.rb`
- **THEN** a read-only buffer named `out.rb` is current and its tab is the selected one

#### Scenario: gd to an outside file already listed shows that buffer and its tab
- **WHEN** `/gems/c.rb` was opened with `:e` and `:bp` went back to `a.rb`, and the answer is one location in `/gems/c.rb`
- **THEN** the listed buffer is shown with its tab selected and no second buffer is listed

#### Scenario: The read-only target's tab selects and closes like the others
- **WHEN** `gd` showed `/gems/c.rb`, and `:bp`, `:bn`, and `:bd` are run in turn
- **THEN** `:bp` shows `a.rb` with its tab selected and the `c.rb` tab kept, `:bn` shows `c.rb` again with its tab selected, and `:bd` closes it, leaving one buffer listed

### Requirement: A read-only buffer is never written
`:w` with or without a name, `:wq`, `:x`, `:wa`, `:wqa`, and the save action SHALL refuse a read-only buffer with `E45: 'readonly' option is set`, no bang overriding it, and leave its file as it was; `:wa` and `:wqa` SHALL still write the other modified buffers.

#### Scenario: Writing a read-only buffer is refused
- **WHEN** `gd` showed the read-only buffer of `/gems/c.rb`, `x` is pressed, and `:w`, `:w /project/copy.rb`, and `:wa` are run in turn
- **THEN** each is refused with E45, `/gems/c.rb` is unchanged, and `/project/copy.rb` does not exist
