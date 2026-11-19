## MODIFIED Requirements

### Requirement: Typing filters the files best match first
Every change of the typed text SHALL filter the listed files again. The text is terms between spaces, and a file SHALL match when its relative path matches every term, in any order, ignoring ASCII case. A text with no term (empty, or only spaces) SHALL list every file in listing order. The highlight SHALL return to the first row. With no match the float SHALL read `No match`.

#### Scenario: Typing filters the files
- **WHEN** the finder lists `lib/alpha.rb`, `lib/beta.rb`, and `docs/guide.md` and the user types `bet`
- **THEN** the float is titled `Files 1/3` and lists only `lib/beta.rb`

#### Scenario: No file matches
- **WHEN** the user types a text no path matches
- **THEN** the float is titled `Files 0/M` and reads `No match`

#### Scenario: A query of spaces lists every file in listing order
- **WHEN** the user types only spaces
- **THEN** every file is listed in listing order

#### Scenario: Ten thousand files are listed and filtered
- **WHEN** the project holds 10,000 files and the user types two letters
- **THEN** the finder lists all 10,000 and shows the matches of the two letters

### Requirement: Matches are ranked best first
Matches SHALL be ordered best first. Every path that holds the term as a substring SHALL rank above every path that holds it only as runs. Among substring matches the order is: inside the file name starting at a segment or word, inside the file name elsewhere, in a directory starting at a segment or word, elsewhere. Among run matches fewer runs rank higher. With several terms a path ranks by its worst term, then by all its terms together. A shorter path breaks a tie, then the listing order.

#### Scenario: The file name match ranks first
- **WHEN** the finder lists `plugins/finder/x.rb` and `lib/plugin.rb` and the user types `plugin`
- **THEN** `lib/plugin.rb` is the first row

#### Scenario: A word start in the file name ranks above a middle byte of it
- **WHEN** the finder lists `lib/alpha.rb` and `lib/beta.rb` and the user types `a`
- **THEN** `lib/alpha.rb` is the first row

#### Scenario: A substring ranks above initials
- **WHEN** the finder lists `a/b.rb` and `x/zzabz/y.rb` and the user types `ab`
- **THEN** `x/zzabz/y.rb` is the first row

#### Scenario: Fewer runs rank above more
- **WHEN** the finder lists `a/b/c/x.rb` and `a/bc/x.rb` and the user types `abc`
- **THEN** `a/bc/x.rb` is the first row

#### Scenario: Explorer in a file name ranks above initials
- **WHEN** the finder lists `tools/explain_pl_or_err.sh`, `carat/plugins/explorer/plugin.rb`, and `test/editor_explorer.rb` and the user types `explorer`
- **THEN** the rows are `test/editor_explorer.rb`, `carat/plugins/explorer/plugin.rb`, and `tools/explain_pl_or_err.sh`

## ADDED Requirements

### Requirement: A path matches a term as a substring or as runs at word starts
A path SHALL match a term in one of two ways and in no other: the term is a contiguous substring of the path, or it is at most four contiguous runs, in order, each run after the first starting at a segment or word start (the first byte, after `/`, `_`, `-`, `.`, or a space, or an uppercase letter after a lowercase one), as initials do. A run that starts inside a word SHALL NOT match.

#### Scenario: Initials match
- **WHEN** the finder lists `lib/alpha.rb`, `lib/beta.rb`, and `docs/guide.md` and the user types `la`
- **THEN** the float is titled `Files 1/3` and lists only `lib/alpha.rb`

#### Scenario: A run that starts mid-word does not match
- **WHEN** the finder lists `lib/alpha.rb`, `lib/beta.rb`, and `docs/guide.md` and the user types `ibh`
- **THEN** the float is titled `Files 0/3` and reads `No match`

#### Scenario: A scattered path is not listed
- **WHEN** the finder lists `ezzzxpzzzlzzzozzzrzzezrrr` and the user types `explorer`
- **THEN** that path is not listed

#### Scenario: Two terms match in any order
- **WHEN** the finder lists `lib/beta.rb` and the user types `beta lib` or `lib beta`
- **THEN** `lib/beta.rb` is listed, and a path that lacks one of the terms is not

#### Scenario: A multi-byte path matches by its bytes
- **WHEN** the finder lists `src/café.rb` and `src/cafe.rb` and the user types `café`
- **THEN** only `src/café.rb` is listed

#### Scenario: Case is ignored
- **WHEN** the finder lists `lib/beta.rb` and the user types `BET`
- **THEN** the float lists `lib/beta.rb`
