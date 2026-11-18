## 1. Palette roles

- [x] 1.1 Add the roles GUIDE and GUIDE_SCOPE to every palette in `carat/domain/themes.rb` and map `IblIndent` and `IblScope` to them, proven by "The guide colors" and "The guides order below Comment" rows in `test/domain_theme.rb`
- [x] 1.2 Exempt Carat's two palettes' guides from the 3:1 floor in the contrast tables of `test/domain_theme.rb`, the other palettes keeping it ("Every palette passes", "Every palette passes on the cursor line")

## 2. The solid scope guide

- [x] 2.1 Add `Options::SCOPE_GUIDE` and `Options#scope_guide_code` (`carat/domain/options.rb`), proven by rows in `test/domain_options_config.rb`
- [x] 2.2 Draw the scope guide with that code in `IndentGuides#paint` and fold the ascii fallback into `configure`'s stamp (`carat/adapters/indent_guides.rb`), proven by "The scope guide is solid" and "The scope guide in ASCII" rows in `test/adapters_indent_guides.rb`

## 3. Docs

- [x] 3.1 Update `docs/compatibility.md` (UI groups, Indent guides) and README.md's option line, checked by `make docs-lint`

## 4. Review fixes

- [x] 4.1 Hold the scope guide as the code-point constant `Options::SCOPE_GUIDE` (0x2502, as `GUIDE_ASCII` is) and return it from `scope_guide_code`, no decode per frame (`carat/domain/options.rb`), proven by the scope guide rows in `test/domain_options_config.rb`
- [x] 4.2 Share one row and column loop between the `marks` and `glyphs` helpers of `test/adapters_indent_guides.rb`, the cell-to-character step extracted
- [x] 4.3 Prove "The other palettes' guides keep 3:1" with the low-contrast entries of `IblIndent` and `IblScope` for one_dark, one_light, dark_plus, and light_plus, on the background and the cursor line, at 24 bits and 256 colors (`test/domain_theme.rb`)
- [x] 4.4 Say in `docs/compatibility.md` that the guides' order holds at 24-bit and 256 colors and that at 16 colors the scope guide is told apart by its solid glyph
