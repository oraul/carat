require_relative "../../plugin_api"

module Carat
  module Plugins
    module Finder
      # Text from a listed file, a path or a line, made safe to show in a
      # float: the one sanitizer of the finder's rows, titles, and previews,
      # since a repository names and fills its files as it likes.
      module SafeText
        # The text with each control character and each invisible format
        # or separator character shown as a space and each byte that forms
        # no valid UTF-8 sequence as "?", so the terminal gets no escape
        # sequence from a file, a row cannot reorder its text to show
        # another path or line, and a valid character beside an invalid
        # byte stays whole.
        #: (String) -> String
        def self.of(text)
          return text if plain?(text)
          out = +""
          n = text.bytesize
          i = 0
          while i < n
            b = text.getbyte(i).to_i
            size = utf8_size(b)
            if size == 1
              out << (b < 0x20 || b == 0x7F ? " " : b.chr)
              i += 1
            elsif size > 1 && i + size <= n && text.byteslice(i, size).to_s.valid_encoding?
              ch = text.byteslice(i, size).to_s
              code = ch.ord
              out << (code < 0xA0 || format_control?(code) ? " " : ch)
              i += size
            else
              out << "?"
              i += 1
            end
          end
          out
        end

        # Whether the text holds only printable ASCII, which of keeps as it
        # is, so a plain text costs no copy.
        #: (String) -> bool
        def self.plain?(text)
          i = 0
          while i < text.bytesize
            b = text.getbyte(i).to_i
            return false if b < 0x20 || b > 0x7E
            i += 1
          end
          true
        end

        # The length of the UTF-8 sequence a lead byte starts, 0 for a byte
        # that starts none.
        #: (Integer) -> Integer
        def self.utf8_size(b)
          return 1 if b < 0x80
          return 2 if b >= 0xC2 && b <= 0xDF
          return 3 if b >= 0xE0 && b <= 0xEF
          return 4 if b >= 0xF0 && b <= 0xF4
          0
        end

        # Whether the code point is an invisible format or separator
        # character: a bidirectional embedding, override, isolate, or mark
        # (U+061C, U+200E, U+200F, U+202A to U+202E, U+2066 to U+2069), a
        # zero-width character (U+200B to U+200D, U+FEFF), or the line or
        # paragraph separator (U+2028, U+2029).
        #: (Integer) -> bool
        def self.format_control?(code)
          code == 0x061C || code == 0xFEFF || (code >= 0x200B && code <= 0x200F) ||
            (code >= 0x2028 && code <= 0x202E) || (code >= 0x2066 && code <= 0x2069)
        end
      end
    end
  end
end
