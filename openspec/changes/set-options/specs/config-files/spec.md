## REMOVED Requirements

### Requirement: :set answers showtabline as not implemented
**Reason**: `:set showtabline=N` and `:set stal=N` now set the option, as the set-command capability's requirement "Number options are set with set" says.
**Migration**: none; the option is read from `option.showtabline` lines as before and set by `:set` too.
