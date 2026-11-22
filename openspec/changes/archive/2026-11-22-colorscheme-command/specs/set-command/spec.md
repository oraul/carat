## MODIFIED Requirements

### Requirement: Word options are set with set
`:se[t]` SHALL take the word options `listchars` (`lcs`), `winborder`, `icons`, `breadcrumbs`, `theme`, and `background` (`bg`) as `name=value`, `name?` and the bare name showing `  name=value`, a backslash keeping a following blank or backslash in the value. A value its `option.*` line would refuse SHALL be `E474: Invalid argument: <argument>`, the value kept; `name+=`, `name-=`, and `name^=` SHALL answer `Not implemented: :set <argument>`.

#### Scenario: Setting a word
- **WHEN** `:set winborder=single` is run
- **THEN** `:set winborder?` shows `  winborder=single`

#### Scenario: A word the configuration refuses
- **WHEN** `:set icons=emoji` is run
- **THEN** the message row shows `E474: Invalid argument: icons=emoji` and `icons` keeps its value

#### Scenario: A blank kept by a backslash
- **WHEN** `:set lcs=tab:>\ ,trail:-` is run
- **THEN** `:set lcs?` shows `  listchars=tab:> ,trail:-`

#### Scenario: Setting the theme and the background
- **WHEN** `:set theme=one_light bg=terminal` is run
- **THEN** `:set theme? bg?` shows `  theme=one_light` and `  background=terminal`, and `:set theme& bg&` gives back `carat-dark` and `theme`

#### Scenario: A theme the configuration refuses
- **WHEN** `:set theme=solarized` is run
- **THEN** the message row shows `E474: Invalid argument: theme=solarized` and the theme is unchanged
