## ADDED Requirements

### Requirement: A root's command serves a working directory under its root
A `language.<name>.lsp.root ROOT COMMAND...` line SHALL name the server command of that language when the working directory is, or is under, ROOT: the words after ROOT SHALL be run as the program and its arguments, as written, with no shell. Elsewhere the language's `language.<name>.lsp` command SHALL run. When several root lines cover the directory, the later line SHALL win. ROOT SHALL follow the rule of a `language.trusted_roots` root.

#### Scenario: A root's command runs under its root
- **WHEN** the user file holds `language.ruby.lsp.root /work docker compose exec app ruby-lsp`, the working directory is `/work/app` under a trusted root, and `a.rb` is opened and the editor is idle
- **THEN** `docker` is started with the arguments `compose exec app ruby-lsp` and the slot reads "docker starting"

#### Scenario: The default command runs outside every root
- **WHEN** the user file holds `language.ruby.lsp.root /work docker compose exec app ruby-lsp`, the working directory is `/project` under a trusted root, and `a.rb` is opened and the editor is idle
- **THEN** `ruby-lsp` is started and the slot reads "ruby-lsp starting"

#### Scenario: The later root line wins
- **WHEN** the user file holds a root line for `/work` naming `docker` and a later one for `/work/app` naming `podman`, and `a.rb` is opened in `/work/app` under a trusted root
- **THEN** `podman` is started

#### Scenario: A root that is no root covers nothing
- **WHEN** the user file holds `language.ruby.lsp.root work docker compose exec app ruby-lsp` and `a.rb` is opened in `/work` under a trusted root
- **THEN** `ruby-lsp` is started
