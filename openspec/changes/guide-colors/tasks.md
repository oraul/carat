## 1. Palette roles

- [x] 1.1 Add the roles GUIDE and GUIDE_SCOPE to every palette in `carat/domain/themes.rb` and map `IblIndent` and `IblScope` to them, proven by "The guide colors" and "The guides order below Comment" rows in `test/domain_theme.rb`
- [x] 1.2 Exempt Carat's two palettes' guides from the 3:1 floor in the contrast tables of `test/domain_theme.rb`, the other palettes keeping it ("Every palette passes", "Every palette passes on the cursor line")

## 2. The solid scope guide

- [x] 2.1 Add `Options::SCOPE_GUIDE_CHAR` and `Options#scope_guide_code` (`carat/domain/options.rb`), proven by rows in `test/domain_options_config.rb`
- [x] 2.2 Draw the scope guide with that code in `IndentGuides#paint` and fold the ascii fallback into `configure`'s stamp (`carat/adapters/indent_guides.rb`), proven by "The scope guide is solid" and "The scope guide in ASCII" rows in `test/adapters_indent_guides.rb`

## 3. Docs

- [ ] 3.1 Update `docs/compatibility.md` (UI groups, Indent guides) and README.md's option line, checked by `make docs-lint`
