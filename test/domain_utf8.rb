require_relative "../carat/test_support"
require_relative "../carat/testing"

# The test is this module's main. test/runner/run_all.rb runs it by name
# with every other test in one program; the guard at the end runs it when
# the file is compiled on its own (make test-one).
module DomainUtf8Test
  D = Carat::Domain
  R = 0xFFFD

  # The code points the decoder gives text, walking it with size_at and
  # code_at as the screen does. A table value is untyped, so it is
  # converted before it reaches the library (docs/spinel-notes.md).
  #: (untyped) -> Array[Integer]
  def self.decoded(value)
    text = value.to_s
    out = []
    bytes = text.bytesize
    i = 0
    while i < bytes
      size = D::Utf8.size_at(text, i, bytes)
      out << D::Utf8.code_at(text, i, size)
      i += size
    end
    out
  end

  # Whether every view of text agrees on its characters: the decoder's
  # walk, Utf8.codes, DecodedLine, and String#length, which the cursor's
  # columns count in.
  #: (untyped) -> bool
  def self.agrees?(value)
    text = value.to_s
    walked = decoded(text)
    line = D::DecodedLine.decode(text, 8)
    walked.length == text.length && D::Utf8.codes(text) == walked && line.size == walked.length
  end

  # The cells the decoded line takes and DisplayWidth's column at its end,
  # which must be equal.
  #: (untyped) -> Array[Integer]
  def self.widths(value)
    text = value.to_s
    [D::DecodedLine.decode(text, 8).width, D::DisplayWidth.column(text, text.length, 8)]
  end

  #: (untyped) -> Integer
  def self.cell(value)
    D::DisplayWidth.cell(value.to_s, 0, 8)
  end

  #: (untyped) -> Array[String]
  def self.split(value)
    D::TextLines.split(value.to_s, false)
  end

  #: (untyped) -> Array[String]
  def self.split_crlf(value)
    D::TextLines.split(value.to_s, true)
  end

  #: (untyped) -> Array[String]
  def self.segments(value)
    Carat::PluginApi::Paths.segments(value.to_s)
  end

  #: (untyped, untyped) -> Integer
  def self.boundary(text, i)
    D::Utf8.boundary(text.to_s, i.to_i)
  end

  #: (untyped) -> bool
  def self.scalar?(value)
    D::Utf8.scalar?(value.to_i)
  end

  def self.main
    t = Carat::Testing.new("domain_utf8")

    # Hostile sequences: every byte outside a well-formed RFC 3629
    # sequence is one U+FFFD.
    t.table([
      ["a truncated two-byte sequence", "\xC3", [R]],
      ["a truncated three-byte sequence", "\xE4\xB8", [R, R]],
      ["a truncated four-byte sequence before a letter", "\xF0\x9F\x98a", [R, R, R, 97]],
      ["an overlong slash in two bytes", "\xC0\xAF", [R, R]],
      ["an overlong lead C1", "\xC1\xBF", [R, R]],
      ["an overlong three-byte NUL", "\xE0\x80\x80", [R, R, R]],
      ["an overlong three-byte form below U+0800", "\xE0\x9F\xBF", [R, R, R]],
      ["an overlong four-byte form below U+10000", "\xF0\x8F\xBF\xBF", [R, R, R, R]],
      ["a high surrogate", "\xED\xA0\x80", [R, R, R]],
      ["a low surrogate", "\xED\xBF\xBF", [R, R, R]],
      ["above U+10FFFF after F4", "\xF4\x90\x80\x80", [R, R, R, R]],
      ["lead byte F5", "\xF5\x80\x80\x80", [R, R, R, R]],
      ["lead byte FF", "\xFF", [R]],
      ["a lone continuation byte", "\x80", [R]],
      ["continuation bytes between letters", "a\x80\xBFb", [97, R, R, 98]],
      ["a Latin-1 letter", "caf\xE9", [99, 97, 102, R]],
      ["a NUL is a character of its own", "a\x00b", [97, 0, 98]]
    ]) do |text|
      decoded(text)
    end

    # Well-formed sequences at the edges of each range decode.
    t.table([
      ["U+0080, the first two-byte", "\xC2\x80", [0x80]],
      ["U+07FF, the last two-byte", "\xDF\xBF", [0x7FF]],
      ["U+0800, the first three-byte", "\xE0\xA0\x80", [0x800]],
      ["U+D7FF, just below the surrogates", "\xED\x9F\xBF", [0xD7FF]],
      ["U+E000, just above the surrogates", "\xEE\x80\x80", [0xE000]],
      ["U+FFFF, the last three-byte", "\xEF\xBF\xBF", [0xFFFF]],
      ["U+10000, the first four-byte", "\xF0\x90\x80\x80", [0x10000]],
      ["U+10FFFF, the last code point", "\xF4\x8F\xBF\xBF", [0x10FFFF]]
    ]) do |text|
      decoded(text)
    end

    # The decoder, Utf8.codes, DecodedLine, and String#length count the
    # same characters, so a cursor column is a cell.
    t.table([
      ["ASCII", "abc", true],
      ["valid UTF-8", "é中\u{1F600}", true],
      ["overlong", "a\xC0\xAFb", true],
      ["surrogate", "\xED\xA0\x80x", true],
      ["above U+10FFFF", "\xF4\x90\x80\x80", true],
      ["truncated at the end", "ab\xE4\xB8", true],
      ["lone continuation", "\x80\x80", true],
      ["NUL", "\x00", true]
    ]) do |text|
      agrees?(text)
    end

    # Every invalid byte is one cell, in the decoded line and in
    # DisplayWidth's column alike.
    t.table([
      ["a surrogate takes three cells, one per byte", "\xED\xA0\x80", [3, 3]],
      ["above U+10FFFF takes four", "\xF4\x90\x80\x80", [4, 4]],
      ["a lone C1 byte is one cell, not a four-cell marker", "a\x9Bb", [3, 3]],
      ["a NUL takes two cells as ^@", "\x00", [2, 2]]
    ]) do |text|
      widths(text)
    end

    # DisplayWidth.cell measures a character as it is drawn.
    t.table([
      ["a letter", "a", 1],
      ["a wide character", "中", 2],
      ["a valid C1 control takes four as <xx>", "\u009B", 4],
      ["a lone byte 9B is U+FFFD, one cell", "\x9B", 1],
      ["a lone byte FF is one cell", "\xFF", 1],
      ["the first byte of an overlong form is one cell", "\xC0", 1]
    ]) do |ch|
      cell(ch)
    end

    t.table([
      ["zero", 0, true],
      ["U+D7FF", 0xD7FF, true],
      ["U+D800", 0xD800, false],
      ["U+DFFF", 0xDFFF, false],
      ["U+E000", 0xE000, true],
      ["U+10FFFF", 0x10FFFF, true],
      ["0x110000", 0x110000, false],
      ["negative", -1, false]
    ]) do |code|
      scalar?(code)
    end

    # The offset byteindex takes: rows are [label, [text, i], offset].
    t.table([
      ["an ASCII byte is a boundary", ["ab", 1], 1],
      ["the continuation bytes of a character are skipped", ["\u00E9!", 1], 2],
      ["lone continuation bytes are skipped", ["a\x80\xBFb", 1], 3],
      ["the end of the text is a boundary", ["a\x80", 1], 2],
      ["an offset past the end stays", ["a", 3], 3]
    ]) do |input|
      boundary(input[0], input[1])
    end

    # TextLines.split answers what split("\n", -1) answers on valid text
    # and splits text that is not UTF-8, which split refuses.
    t.table([
      ["empty text has no pieces", "", []],
      ["one line", "ab", ["ab"]],
      ["a trailing newline gives an empty last piece", "a\nb\n", ["a", "b", ""]],
      ["only a newline", "\n", ["", ""]],
      ["blank lines", "a\n\n\nb", ["a", "", "", "b"]],
      ["a carriage return is kept without crlf", "a\r\nb", ["a\r", "b"]],
      ["illegal bytes stay in their pieces", "\xFFa\n\xC0\xAF\n\x80", ["\xFFa", "\xC0\xAF", "\x80"]]
    ]) do |text|
      split(text)
    end

    t.table([
      ["crlf drops the carriage return before each newline", "a\r\nb\r\n", ["a", "b", ""]],
      ["a lone carriage return stays", "a\rb\r\nc\r", ["a\rb", "c\r"]],
      ["with an illegal byte", "\xFFa\r\nb", ["\xFFa", "b"]]
    ]) do |text|
      split_crlf(text)
    end

    valid = "one\n\ntwo\nthree\n"
    t.assert_equal(valid.split("\n", -1), split(valid), "split agrees with String#split on valid text")

    # The plugin API's path segments cut by bytes.
    t.table([
      ["an absolute path", "/a/./b/../c", ["a", "c"]],
      ["a relative path keeps a leading ..", "../x//y/", ["..", "x", "y"]],
      ["a name that is not UTF-8", "/proj/caf\xE9/\xF4\x90\x80\x80.md", ["proj", "caf\xE9", "\xF4\x90\x80\x80.md"]],
      ["a name that starts with a continuation byte", "/a/\x80b", ["a", "\x80b"]]
    ]) do |path|
      segments(path)
    end

    t.finish
  end
end

DomainUtf8Test.main if __FILE__ == $0
