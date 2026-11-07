## ADDED Requirements

### Requirement: The icon table holds the completion kinds
The table SHALL also hold, in each set and under the same rules for each set, a glyph for the completion kind names kind_text, kind_method, kind_function, kind_constructor, kind_field, kind_variable, kind_class, kind_module, kind_property, kind_keyword, kind_snippet, and kind_constant.

#### Scenario: Every kind in every set
- **WHEN** each kind name is looked up in each set
- **THEN** each yields a non-empty glyph, the nerd glyphs are in the private use areas, the ascii glyphs are ASCII, and the unicode glyphs are neither

#### Scenario: A completion kind
- **WHEN** "kind_function" is looked up in the ascii set
- **THEN** the glyph is "f"
