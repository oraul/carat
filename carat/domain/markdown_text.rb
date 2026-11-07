require_relative "control_text"
require_relative "display_width"
require_relative "utf8"

module Carat
  module Domain
    # Documentation markdown from a program (a language server's completion
    # item) as plain rows for a float, the text untrusted: at most
    # RAW_LIMIT bytes are read, escape sequences and controls dropped
    # (ControlText), and at most ROW_LIMIT rows kept. A fence line toggles
    # code, whose lines keep their text indented by two spaces; any other
    # line loses its block markers (quote levels read as BAR each, at most
    # NEST_LIMIT of them, as is the indentation; heading markers; a list
    # marker reads as BULLET; a thematic break as RULE) and its inline
    # markup (backticks, emphasis at word boundaries, a link or an image as
    # its text, a backslash escape as its character). Runs of blank rows
    # read as one, none leads or trails, and a row wider than the width
    # wraps at its last space after text, or on a character boundary when
    # it has none, never inside its prefix. One pass over the bytes,
    # nothing recursive, so nesting costs nothing beyond its cap.
    module MarkdownText
      RAW_LIMIT = 16_384
      ROW_LIMIT = 100
      NEST_LIMIT = 4
      BULLET = "• "
      BAR = "│ "
      RULE = "────────────────────"
      PUNCTUATION = '!"#$%&\'()*+,-./:;<=>?@[\\]^_`{|}~'

      # The rows of the text, each at most width cells wide.
      #: (String, Integer) -> Array[String]
      def self.rows(text, width)
        raw = text.bytesize > RAW_LIMIT ? text.byteslice(0, RAW_LIMIT).to_s : text
        body = ControlText.without_sequences(raw)
        out = [""]
        out.clear
        code = false
        gap = false
        len = body.bytesize
        start = 0
        while start <= len && out.length < ROW_LIMIT
          found = body.byteindex("\n", start)
          stop = found.nil? ? len : found.to_i
          line = ControlText.line(body.byteslice(start, stop - start).to_s, RAW_LIMIT)
          start = stop + 1
          if fence?(line)
            code = !code
            next
          end
          row = code ? "  " + line.rstrip : block(line).rstrip
          if row.strip.empty?
            gap = !out.empty?
            next
          end
          out << "" if gap
          gap = false
          out = wrapped(row, width, out)
        end
        out.pop while out.length > ROW_LIMIT
        out.pop while !out.empty? && out[out.length - 1].to_s.empty?
        out
      end

      # Whether the line opens or closes fenced code: at most three spaces,
      # then three backticks or tildes.
      #: (String) -> bool
      def self.fence?(line)
        i = 0
        i += 1 while i < 3 && line.getbyte(i).to_i == 0x20
        mark = line.getbyte(i).to_i
        return false unless mark == 0x60 || mark == 0x7E
        line.getbyte(i + 1).to_i == mark && line.getbyte(i + 2).to_i == mark
      end

      # A line outside code with its block markers read and its inline
      # markup taken out.
      #: (String) -> String
      def self.block(line)
        len = line.bytesize
        i = 0
        i += 1 while i < len && line.getbyte(i).to_i == 0x20
        indent = i / 2
        depth = 0
        while i < len && line.getbyte(i).to_i == 0x3E
          depth += 1
          i += 1
          i += 1 while i < len && line.getbyte(i).to_i == 0x20
        end
        depth = NEST_LIMIT if depth > NEST_LIMIT
        indent = NEST_LIMIT if indent > NEST_LIMIT
        out = +""
        depth.times { out << BAR }
        indent.times { out << "  " }
        rest = line.byteslice(i, len - i).to_s
        if rule?(rest)
          out << RULE
          return out
        end
        rest = heading_text(rest)
        mark = rest.getbyte(0).to_i
        if (mark == 0x2D || mark == 0x2A || mark == 0x2B) && rest.getbyte(1).to_i == 0x20
          out << BULLET
          rest = rest.byteslice(2, rest.bytesize - 2).to_s
        end
        out << inline(rest)
        out
      end

      # Whether the text is a thematic break: three or more of one of -, *,
      # or _ and nothing else but spaces.
      #: (String) -> bool
      def self.rule?(text)
        mark = text.getbyte(0).to_i
        return false unless mark == 0x2D || mark == 0x2A || mark == 0x5F
        count = 0
        i = 0
        while i < text.bytesize
          b = text.getbyte(i).to_i
          if b == mark
            count += 1
          elsif b != 0x20
            return false
          end
          i += 1
        end
        count >= 3
      end

      # The text after one to six heading markers and a space, else the
      # text.
      #: (String) -> String
      def self.heading_text(text)
        len = text.bytesize
        i = 0
        i += 1 while i < len && i < 7 && text.getbyte(i).to_i == 0x23
        return text if i == 0 || i > 6
        return "" if i == len
        return text unless text.getbyte(i).to_i == 0x20
        text.byteslice(i + 1, len - i - 1).to_s
      end

      # The text without its inline markup. A link's or an image's text is
      # gathered apart from its opening bracket until "](" ends it and its
      # target is skipped to ")"; another bracket, a "]" not followed by
      # "(", or the end gives the bracket back, so every byte is read once.
      #: (String) -> String
      def self.inline(text)
        out = +""
        link = +""
        open = false
        closes = true
        len = text.bytesize
        i = 0
        while i < len
          b = text.getbyte(i).to_i
          target = open ? link : out
          if b == 0x5C && i + 1 < len && PUNCTUATION.include?(text.byteslice(i + 1, 1).to_s)
            target << text.byteslice(i + 1, 1).to_s
            i += 2
          elsif b == 0x60
            i += 1
          elsif b == 0x21 && text.getbyte(i + 1).to_i == 0x5B
            i += 1
          elsif b == 0x5B
            if open
              out << "["
              out << link
            end
            link = +""
            open = true
            i += 1
          elsif b == 0x5D && open && text.getbyte(i + 1).to_i == 0x28 && closes
            found = text.byteindex(")", i + 2)
            open = false
            if found.nil?
              closes = false
              out << "["
              out << link
              out << "]"
              i += 1
            else
              out << link
              i = found.to_i + 1
            end
          elsif b == 0x5D && open
            out << "["
            out << link
            out << "]"
            open = false
            i += 1
          elsif b == 0x2A || b == 0x5F
            size = text.getbyte(i + 1).to_i == b ? 2 : 1
            target << text.byteslice(i, size).to_s unless emphasis?(text, i, size)
            i += size
          else
            size = b < 0x80 ? 1 : Utf8.size_at(text, i, len)
            target << text.byteslice(i, size).to_s
            i += size
          end
        end
        if open
          out << "["
          out << link
        end
        out
      end

      # Whether the marker of size bytes at i opens emphasis (no word
      # character before it, no space after it) or closes it (no space
      # before it, no word character after it), so a marker inside a word
      # (file_name) or between spaces (a * b) is kept.
      #: (String, Integer, Integer) -> bool
      def self.emphasis?(text, i, size)
        before = i > 0 ? text.getbyte(i - 1).to_i : 0x20
        after = i + size < text.bytesize ? text.getbyte(i + size).to_i : 0x20
        (!word?(before) && after != 0x20) || (before != 0x20 && !word?(after))
      end

      # Whether the byte belongs to a word: an ASCII letter or digit, or a
      # byte of a character outside ASCII.
      #: (Integer) -> bool
      def self.word?(b)
        (b >= 0x30 && b <= 0x39) || (b >= 0x41 && b <= 0x5A) || (b >= 0x61 && b <= 0x7A) || b >= 0x80
      end

      # The bytes of the row's prefix: its leading spaces, bars, and
      # bullet.
      #: (String) -> Integer
      def self.prefix_size(row)
        len = row.bytesize
        i = 0
        while i < len
          if row.getbyte(i).to_i == 0x20
            i += 1
          elsif row.byteslice(i, BAR.bytesize).to_s == BAR
            i += BAR.bytesize
          elsif row.byteslice(i, BULLET.bytesize).to_s == BULLET
            i += BULLET.bytesize
          else
            return i
          end
        end
        i
      end

      # The rows with the row added, wrapped at width cells: at its last
      # space before the width that follows text of the segment, or on a
      # character boundary when it has none. The row's prefix (its leading
      # spaces, bars, and bullet) is not text, so a code indent, a bullet,
      # or a bar is never left alone on a row.
      #: (String, Integer, Array[String]) -> Array[String]
      def self.wrapped(row, width, out)
        len = row.bytesize
        prefix = prefix_size(row)
        start = 0
        used = 0
        space = -1
        seen = false
        i = 0
        while i < len
          size = Utf8.size_at(row, i, len)
          cells = DisplayWidth.of(Utf8.code_at(row, i, size))
          if used + cells > width && i > start
            cut = space > start ? space : i
            out << row.byteslice(start, cut - start).to_s.rstrip
            return out if out.length >= ROW_LIMIT
            start = space > start ? space + 1 : i
            i = start
            used = 0
            space = -1
            seen = false
            next
          end
          b = row.getbyte(i).to_i
          if b == 0x20
            space = i if seen
          elsif i >= prefix
            seen = true
          end
          used += cells
          i += size
        end
        out << row.byteslice(start, len - start).to_s if start < len
        out
      end
    end
  end
end
