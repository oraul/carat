require_relative "../carat/test_support"
require_relative "../carat/testing"

# The test is this module's main. test/runner/run_all.rb runs it by name
# with every other test in one program; the guard at the end runs it when
# the file is compiled on its own (make test-one).
module DomainDisplayWidthTest
  D = Carat::Domain

  # DisplayWidth.cut of a [text, width] row.
  def self.cut(value)
    D::DisplayWidth.cut(Carat::Json.element(value, 0).to_s, Carat::Json.element(value, 1).to_i)
  end

  # DisplayWidth.fit of a [text, width] row.
  def self.fit(value)
    D::DisplayWidth.fit(Carat::Json.element(value, 0).to_s, Carat::Json.element(value, 1).to_i)
  end

  # The cells DisplayWidth.fit of a [text, width] row takes.
  def self.fit_cells(value)
    D::DisplayWidth.text_width(fit(value), 0)
  end

  # DisplayWidth.bytes_within of a [text, width] row.
  def self.bytes_within(value)
    D::DisplayWidth.bytes_within(Carat::Json.element(value, 0).to_s, Carat::Json.element(value, 1).to_i)
  end

  def self.main
    t = Carat::Testing.new("domain_display_width")

    # DisplayWidth.cut keeps whole characters within the width in cells.
    # Rows are [label, [text, width], cut text].
    t.table([
      ["ASCII that fits is kept whole", ["abc", 5], "abc"],
      ["ASCII is cut to the width", ["abcdef", 3], "abc"],
      ["a wide character that would pass the width is dropped", ["あいう", 5], "あい"],
      ["wide characters fill the width exactly", ["あいう", 4], "あい"],
      ["seven wide characters cut to 11 cells keep five", ["あいうえおかき", 11], "あいうえお"],
      ["a combining mark stays with its letter", ["ééé", 2], "éé"],
      ["a combining mark after a dropped character is dropped", ["aあ́", 2], "a"],
      ["combining marks take no cell", ["á̂b", 2], "á̂b"],
      ["a control character takes one cell", ["a\tbc", 2], "a\t"],
      ["a zero width is empty", ["abc", 0], ""],
      ["a negative width is empty", ["あ", -3], ""],
      ["an empty text stays empty", ["", 4], ""]
    ]) do |row|
      cut(row)
    end

    # DisplayWidth.fit cuts, then pads with spaces to the width.
    # Rows are [label, [text, width], fitted text].
    t.table([
      ["a short text is padded", ["ab", 4], "ab  "],
      ["a text of the width is unchanged", ["abcd", 4], "abcd"],
      ["a long text is cut without a pad", ["abcdef", 3], "abc"],
      ["a wide character cut at the edge leaves one space", ["あいう", 5], "あい "],
      ["a key of seven wide characters fits 11 cells", ["あいうえおかき", 11], "あいうえお "],
      ["a wide character wider than the width becomes spaces", ["あ", 1], " "],
      ["a combining mark is padded by its letter's cells", ["éx", 3], "éx "],
      ["a negative width is empty", ["abc", -1], ""]
    ]) do |row|
      fit(row)
    end

    # The fitted text takes exactly the width. Rows are [label, [text,
    # width], cells].
    t.table([
      ["wide characters at an odd width", ["あいうえおかきくけこさしす", 11], 11],
      ["wide characters at an even width", ["あいうえおかきくけこさしす", 12], 12],
      ["combining marks over the width", ["é" * 20, 12], 12],
      ["mixed wide and combining", ["aあéい", 5], 5]
    ]) do |row|
      fit_cells(row)
    end

    # bytes_within measures invalid UTF-8 as the frame decodes it: each
    # stray byte one cell. Rows are [label, [text, width], bytes].
    t.table([
      ["a stray byte is one cell", ["a\xFFb", 2], 2],
      ["a wide character is three bytes", ["あい", 2], 3],
      ["a combining mark adds its bytes", ["éz", 1], 3]
    ]) do |row|
      bytes_within(row)
    end

    text = "keep"
    t.assert_equal(true, D::DisplayWidth.cut(text, 10).equal?(text), "a text that fits is answered itself, not copied")

    # DisplayWidth.format_char? names the code points shown as <xxxx>, and
    # code_cells gives each six cells.
    t.table([
      ["a letter", 0x61, [false, 1]],
      ["U+061B, before the Arabic letter mark", 0x061B, [false, 1]],
      ["U+061C, the Arabic letter mark", 0x061C, [true, 6]],
      ["U+200A, a hair space", 0x200A, [false, 1]],
      ["U+200B, a zero width space", 0x200B, [true, 6]],
      ["U+200F, a right-to-left mark", 0x200F, [true, 6]],
      ["U+2010, a hyphen", 0x2010, [false, 1]],
      ["U+2027, before the separators", 0x2027, [false, 1]],
      ["U+2028, the line separator", 0x2028, [true, 6]],
      ["U+202E, a right-to-left override", 0x202E, [true, 6]],
      ["U+202F, a narrow no-break space", 0x202F, [false, 1]],
      ["U+205F, before the word joiner", 0x205F, [false, 1]],
      ["U+2060, the word joiner", 0x2060, [true, 6]],
      ["U+206F, the last invisible operator", 0x206F, [true, 6]],
      ["U+2070, a superscript zero", 0x2070, [false, 1]],
      ["U+FEFF, the byte order mark", 0xFEFF, [true, 6]],
      ["U+FF00, a fullwidth form", 0xFF00, [false, 2]],
      ["delete stays a four-cell control", 0x7F, [false, 4]]
    ]) do |code|
      [D::DisplayWidth.format_char?(code.to_i), D::DisplayWidth.code_cells(code.to_i, 0, 8)]
    end

    t.finish
  end
end

DomainDisplayWidthTest.main if __FILE__ == $0
