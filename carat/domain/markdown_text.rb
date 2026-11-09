require_relative "control_text"
require_relative "display_width"
require_relative "docs_text"
require_relative "highlight"
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
      SYNTAX_LIMIT = 32

      # The rows of the text, each at most width cells wide.
      #: (String, Integer) -> Array[String]
      def self.rows(text, width)
        wrap(parse(text), width).texts
      end

      # The text read into rows not yet wrapped, with their spans, at most
      # ROW_LIMIT of them.
      #: (String) -> DocsText
      def self.parse(text)
        raw = text.bytesize > RAW_LIMIT ? text.byteslice(0, RAW_LIMIT).to_s : text
        body = ControlText.without_sequences(raw)
        doc = DocsText.new
        code = false
        syntax = ""
        fenced = 0
        gap = false
        len = body.bytesize
        start = 0
        while start <= len && doc.count < ROW_LIMIT
          found = body.byteindex("\n", start)
          stop = found.nil? ? len : found.to_i
          line = ControlText.line(body.byteslice(start, stop - start).to_s, RAW_LIMIT)
          start = stop + 1
          if fence?(line)
            code = !code
            if code
              fenced += 1
              syntax = fence_syntax(line)
            end
            next
          end
          at = gap ? doc.count + 1 : doc.count
          row = code ? "  " + line.rstrip : block(line, doc, at).rstrip
          if row.strip.empty?
            doc.drop_spans(at)
            gap = doc.count > 0
            next
          end
          doc.add_row("", "", 0) if gap
          gap = false
          if code
            doc.add_row(row, syntax, fenced)
            doc.add_span(at, 2, char_count(row), Highlight::MARKUP_RAW_BLOCK)
          else
            doc.add_row(row, "", 0)
          end
        end
        doc
      end

      # The rows of a parsed text wrapped at width cells, their spans cut
      # with them, at most ROW_LIMIT rows and no empty one at the end.
      #: (DocsText, Integer) -> DocsText
      def self.wrap(doc, width)
        out = DocsText.new
        row = 0
        while row < doc.count && out.count < ROW_LIMIT
          out = wrapped(doc, row, width, out)
          row += 1
        end
        out.trim
        out
      end

      # The language a fence's info string names: its first word, at most
      # SYNTAX_LIMIT bytes of ASCII, "" for none.
      #: (String) -> String
      def self.fence_syntax(line)
        len = line.bytesize
        i = 0
        i += 1 while i < len && line.getbyte(i).to_i == 0x20
        mark = line.getbyte(i).to_i
        i += 1 while i < len && line.getbyte(i).to_i == mark
        i += 1 while i < len && line.getbyte(i).to_i == 0x20
        from = i
        while i < len && i - from < SYNTAX_LIMIT
          b = line.getbyte(i).to_i
          break if b <= 0x20 || b >= 0x7F
          i += 1
        end
        line.byteslice(from, i - from).to_s
      end

      # The number of characters of a text.
      #: (String) -> Integer
      def self.char_count(text)
        len = text.bytesize
        i = 0
        n = 0
        while i < len
          i += Utf8.size_at(text, i, len)
          n += 1
        end
        n
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
      # markup taken out, its spans added to the document's row at.
      #: (String, DocsText, Integer) -> String
      def self.block(line, doc, at)
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
        offset = (depth + indent) * 2
        heading = heading?(rest)
        rest = heading_text(rest)
        doc.add_span(at, offset, offset + RAW_LIMIT, Highlight::MARKUP_HEADING) if heading
        mark = rest.getbyte(0).to_i
        if (mark == 0x2D || mark == 0x2A || mark == 0x2B) && rest.getbyte(1).to_i == 0x20
          out << BULLET
          offset += 2
          rest = rest.byteslice(2, rest.bytesize - 2).to_s
        end
        out << inline(rest, offset, doc, at)
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

      # Whether the text is a heading: one to six markers, then a space or
      # nothing.
      #: (String) -> bool
      def self.heading?(text)
        len = text.bytesize
        i = 0
        i += 1 while i < len && i < 7 && text.getbyte(i).to_i == 0x23
        return false if i == 0 || i > 6
        i == len || text.getbyte(i).to_i == 0x20
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
      # The spans of its code spans, strong and emphasized runs, and link
      # texts are added to the document's row at, the text starting at
      # column offset; a run left open has none.
      #: (String, Integer, DocsText, Integer) -> String
      def self.inline(text, offset, doc, at)
        out = +""
        link = +""
        open = false
        closes = true
        col = offset
        link_cols = 0
        code_from = -1
        strong_from = -1
        italic_from = -1
        len = text.bytesize
        i = 0
        while i < len
          b = text.getbyte(i).to_i
          target = open ? link : out
          if b == 0x5C && i + 1 < len && PUNCTUATION.include?(text.byteslice(i + 1, 1).to_s)
            target << text.byteslice(i + 1, 1).to_s
            if open
              link_cols += 1
            else
              col += 1
            end
            i += 2
          elsif b == 0x60
            unless open
              if code_from < 0
                code_from = col
              else
                doc.add_span(at, code_from, col, Highlight::MARKUP_RAW)
                code_from = -1
              end
            end
            i += 1
          elsif b == 0x21 && text.getbyte(i + 1).to_i == 0x5B
            i += 1
          elsif b == 0x5B
            if open
              out << "["
              out << link
              col += 1 + link_cols
            end
            link = +""
            link_cols = 0
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
              col += 2 + link_cols
              i += 1
            else
              doc.add_span(at, col, col + link_cols, Highlight::MARKUP_LINK)
              out << link
              col += link_cols
              i = found.to_i + 1
            end
          elsif b == 0x5D && open
            out << "["
            out << link
            out << "]"
            col += 2 + link_cols
            open = false
            i += 1
          elsif b == 0x2A || b == 0x5F
            size = text.getbyte(i + 1).to_i == b ? 2 : 1
            if !emphasis?(text, i, size)
              target << text.byteslice(i, size).to_s
              if open
                link_cols += size
              else
                col += size
              end
            elsif !open && code_from < 0 && size == 2
              if strong_from < 0
                strong_from = col
              else
                doc.add_span(at, strong_from, col, Highlight::MARKUP_STRONG)
                strong_from = -1
              end
            elsif !open && code_from < 0
              if italic_from < 0
                italic_from = col
              else
                doc.add_span(at, italic_from, col, Highlight::MARKUP_ITALIC)
                italic_from = -1
              end
            end
            i += size
          else
            size = b < 0x80 ? 1 : Utf8.size_at(text, i, len)
            target << text.byteslice(i, size).to_s
            if open
              link_cols += 1
            else
              col += 1
            end
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

      # The rows with the document's row added, wrapped at width cells:
      # at its last space before the width that follows text of the
      # segment, or on a character boundary when it has none, each piece
      # with the row's spans cut to it. The row's prefix (its leading
      # spaces, bars, and bullet) is not text, so a code indent, a bullet,
      # or a bar is never left alone on a row.
      #: (DocsText, Integer, Integer, DocsText) -> DocsText
      def self.wrapped(doc, row, width, out)
        text = doc.line(row)
        syntax = doc.syntax(row)
        fenced = doc.block(row)
        len = text.bytesize
        if len == 0
          out.add_row(text, syntax, fenced)
          return out
        end
        prefix = prefix_size(text)
        start = 0
        start_col = 0
        used = 0
        space = -1
        space_col = -1
        seen = false
        i = 0
        col = 0
        while i < len
          size = Utf8.size_at(text, i, len)
          cells = DisplayWidth.of(Utf8.code_at(text, i, size))
          if used + cells > width && i > start
            at_space = space > start
            cut = at_space ? space : i
            cut_col = at_space ? space_col : col
            at = out.add_row(text.byteslice(start, cut - start).to_s.rstrip, syntax, fenced)
            out.copy_spans(doc, row, start_col, cut_col, at)
            return out if out.count >= ROW_LIMIT
            start = at_space ? space + 1 : i
            start_col = at_space ? space_col + 1 : col
            i = start
            col = start_col
            used = 0
            space = -1
            seen = false
            next
          end
          b = text.getbyte(i).to_i
          if b == 0x20
            if seen
              space = i
              space_col = col
            end
          elsif i >= prefix
            seen = true
          end
          used += cells
          i += size
          col += 1
        end
        if start < len
          at = out.add_row(text.byteslice(start, len - start).to_s, syntax, fenced)
          out.copy_spans(doc, row, start_col, col, at)
        end
        out
      end
    end
  end
end
