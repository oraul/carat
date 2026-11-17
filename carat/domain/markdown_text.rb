require_relative "control_text"
require_relative "display_width"
require_relative "docs_text"
require_relative "highlight"
require_relative "utf8"

module Carat
  module Domain
    # Markdown from a program (a language server's documentation) or a
    # file (the reading view) as rows with their markup spans, the text
    # untrusted: at most raw_limit bytes are read (RAW_LIMIT for
    # documentation, READING_RAW_LIMIT for a file), escape sequences and
    # controls dropped (ControlText), and at most row_limit rows kept
    # (ROW_LIMIT or READING_ROW_LIMIT). A fence line toggles code, whose
    # lines keep their text indented by two spaces and carry the fence's
    # language and block number; any other line loses its block markers
    # (quote levels read as a bar each, at most NEST_LIMIT of them, as is
    # the indentation; heading markers; a list marker reads as a bullet; a
    # thematic break as a rule, the three drawn from the icon set, plain
    # ASCII for "ascii") and its inline markup (backticks, emphasis at word
    # boundaries, a link or an image as its text, a backslash escape as its
    # character). A table (a header row, a separator row, and the rows
    # holding a pipe after it) is drawn by parse at the width as aligned
    # columns in borders from the icon set, its cells wrapped when it is
    # wider, so wrap leaves its rows whole; one the width cannot draw
    # keeps each of its source lines its own row. The lines of a
    # paragraph, and those of a quote at one depth and indentation, flow
    # into one row until a blank line, another block, or a line ending
    # in two spaces, and a wrapped row's prefix starts each of its
    # continuation rows.
    # parse keeps a span (Highlight group) for each heading, strong and
    # emphasized run, code span, link text, and fenced row; wrap cuts
    # them with the rows. gather joins a file's lines up to the raw cap.
    # Runs of blank rows read as one, none leads or trails, and a row
    # wider than the width wraps at its last space after text, or on a
    # character boundary when it has none, never inside its prefix. One
    # pass over the bytes, nothing recursive, so
    # nesting costs nothing beyond its cap.
    module MarkdownText
      RAW_LIMIT = 16_384
      ROW_LIMIT = 100
      NEST_LIMIT = 4
      BULLET = "• "
      BAR = "│ "
      RULE = "────────────────────"
      ASCII_BULLET = "* "
      ASCII_BAR = "| "
      ASCII_RULE = "--------------------"
      READING_RAW_LIMIT = 262_144
      READING_ROW_LIMIT = 10_000
      PUNCTUATION = '!"#$%&\'()*+,-./:;<=>?@[\\]^_`{|}~'
      SYNTAX_LIMIT = 32
      BOX = ["┌", "┬", "┐", "├", "┼", "┤", "└", "┴", "┘", "─", "│"]
      ASCII_BOX = ["+", "+", "+", "+", "+", "+", "+", "+", "+", "-", "|"]
      BOX_TOP = 0
      BOX_MIDDLE = 3
      BOX_BOTTOM = 6
      BOX_LINE = 9
      BOX_SIDE = 10
      ALIGN_LEFT = 0
      ALIGN_CENTER = 1
      ALIGN_RIGHT = 2
      CELL_MIN = 2
      MARKER_INDENT = 16
      FRAME_MIN = 6

      # The text read into rows, with their spans, at most row_limit of
      # them, read from at most raw_limit bytes, its markers those of the
      # icon set; the rows of a table are drawn at width cells, the others
      # not yet wrapped.
      #: (String, String, Integer, Integer, Integer) -> DocsText
      def self.parse(text, set, raw_limit, row_limit, width)
        raw = text.bytesize > raw_limit ? text.byteslice(0, raw_limit).to_s : text
        body = ControlText.without_sequences(raw)
        doc = DocsText.new
        code = false
        syntax = ""
        fenced = 0
        gap = false
        flow = -1
        flow_cols = 0
        flowing = +""
        flowing_row = -1
        source = false
        len = body.bytesize
        start = 0
        while start <= len && doc.count < row_limit
          found = body.byteindex("\n", Utf8.boundary(body, start))
          stop = found.nil? ? len : found.to_i
          line = ControlText.line(body.byteslice(start, stop - start).to_s, raw_limit)
          start = stop + 1
          if fence?(line)
            code = !code
            flow = -1
            source = false
            if code
              fenced += 1
              syntax = fence_syntax(line)
            end
            next
          end
          if !code && line.include?("|")
            after = table(body, start, line, doc, set, raw_limit, row_limit, width, gap)
            if after >= 0
              start = after
              gap = false
              flow = -1
              next
            end
            source = after == -2 || (source && !opens_block?(line))
          else
            source = false
          end
          key = code || source ? -1 : flow_key(line)
          if key >= 0 && key == flow && !gap
            at = doc.count - 1
            if flowing_row != at
              flowing = +""
              flowing << doc.line(at)
              doc.last_line = flowing
              flowing_row = at
            end
            piece = inline(line.byteslice(marker_end(line), line.bytesize).to_s, flow_cols + 1, doc, at).rstrip
            unless piece.empty?
              flowing << " "
              flowing << piece
              flow_cols += 1 + char_count(piece)
            end
            flow = line.end_with?("  ") ? -1 : key
            next
          end
          at = gap ? doc.count + 1 : doc.count
          row = code ? "  " + line.rstrip : block(line, doc, at, set, raw_limit).rstrip
          if row.strip.empty?
            doc.drop_spans(at)
            gap = doc.count > 0
            flow = -1
            next
          end
          doc.add_row("", "", 0) if gap
          gap = false
          flow = key >= 0 && !line.end_with?("  ") ? key : -1
          flow_cols = char_count(row) if flow >= 0
          if code
            doc.add_row(row, syntax, fenced)
            doc.add_span(at, 2, char_count(row), Highlight::MARKUP_RAW_BLOCK)
          else
            doc.add_row(row, "", 0)
          end
        end
        doc
      end

      # The flow key of a line outside code: its quote depth, capped at
      # NEST_LIMIT, and its indentation level, as one number, so that a
      # line with the key of the paragraph or quote row before it joins
      # that row; -1 for a line that takes no part in a flow (blank or a
      # bare quote marker, a thematic break, a heading, a list item, or a
      # line whose text is indented four or more spaces, inside a quote
      # or not, an indented code block or a verbatim example, which keeps
      # its rows). A flowing line's indentation is under four spaces, so
      # its level is 0 or 1 and needs no cap.
      #: (String) -> Integer
      def self.flow_key(line)
        scan = markers(line)
        indent = marker_indent(scan)
        return -1 if indent >= 4
        i = marker_stop(scan)
        len = line.bytesize
        return -1 if i >= len
        rest = line.byteslice(i, len - i).to_s
        return -1 if rule?(rest) || heading?(rest) || item?(rest)
        marker_depth(scan) * 2 + indent / 2
      end

      # The byte after a line's leading spaces and quote markers, each
      # marker's spaces included: where its text starts, as block and
      # flow_key read it.
      #: (String) -> Integer
      def self.marker_end(line)
        marker_stop(markers(line))
      end

      # The one scan of a line's leading spaces and quote markers that
      # flow_key, marker_end, and block share: under four leading spaces, each
      # ">" and the spaces after it, the text's indentation being the
      # spaces after the last marker less the one the marker takes, and
      # the scan ending after a marker followed by four or more (an
      # indented code line in the quote, whose next ">" is text); with no
      # marker the indentation is the leading spaces, and four or more
      # read no marker (an indented code line). The byte after the scan,
      # the depth capped at NEST_LIMIT, and the indentation capped at
      # MARKER_INDENT - 1 packed in one Integer, read by marker_stop,
      # marker_depth, and marker_indent, so no line allocates.
      #: (String) -> Integer
      def self.markers(line)
        len = line.bytesize
        i = 0
        i += 1 while i < len && line.getbyte(i).to_i == 0x20
        indent = i
        depth = 0
        while indent < 4 && i < len && line.getbyte(i).to_i == 0x3E
          depth += 1
          i += 1
          from = i
          i += 1 while i < len && line.getbyte(i).to_i == 0x20
          indent = i > from ? i - from - 1 : 0
        end
        depth = NEST_LIMIT if depth > NEST_LIMIT
        indent = MARKER_INDENT - 1 if indent >= MARKER_INDENT
        (i * (NEST_LIMIT + 1) + depth) * MARKER_INDENT + indent
      end

      # The byte after the scan of markers.
      #: (Integer) -> Integer
      def self.marker_stop(scan)
        scan / MARKER_INDENT / (NEST_LIMIT + 1)
      end

      # The quote depth of the scan of markers, at most NEST_LIMIT.
      #: (Integer) -> Integer
      def self.marker_depth(scan)
        scan / MARKER_INDENT % (NEST_LIMIT + 1)
      end

      # The spaces the text is indented by in the scan of markers, at
      # most MARKER_INDENT - 1.
      #: (Integer) -> Integer
      def self.marker_indent(scan)
        scan % MARKER_INDENT
      end

      # Whether the text opens a list item: a -, *, or + and a space, or
      # digits and a . or ) and a space.
      #: (String) -> bool
      def self.item?(text)
        mark = text.getbyte(0).to_i
        return text.getbyte(1).to_i == 0x20 if mark == 0x2D || mark == 0x2A || mark == 0x2B
        i = 0
        i += 1 while i < 9 && text.getbyte(i).to_i >= 0x30 && text.getbyte(i).to_i <= 0x39
        return false if i == 0
        stop = text.getbyte(i).to_i
        (stop == 0x2E || stop == 0x29) && text.getbyte(i + 1).to_i == 0x20
      end

      # Whether a line after a table's rows opens another block, which
      # ends the table: after its leading spaces a quote marker, a
      # heading, a list item, or a fence.
      #: (String) -> bool
      def self.opens_block?(line)
        rest = line.lstrip
        rest.getbyte(0).to_i == 0x3E || heading?(rest) || item?(rest) || fence?(line)
      end

      # The rows of a parsed text wrapped at width cells, their spans cut
      # with them, at most row_limit rows and no empty one at the end, the
      # prefixes those of the icon set; when framed (the reading view)
      # each fenced block is drawn in a frame of the icon set, given a
      # width of at least FRAME_MIN cells.
      #: (DocsText, Integer, String, Integer, bool) -> DocsText
      def self.wrap(doc, width, set, row_limit, framed)
        out = DocsText.new
        row = 0
        while row < doc.count && out.count < row_limit
          if framed && width >= FRAME_MIN && doc.block(row) > 0
            row = frame(doc, row, width, out, set, row_limit)
          else
            out = wrapped(doc, row, width, out, set, row_limit)
            row += 1
          end
        end
        out.trim
        out
      end

      # Draws the fenced block whose first row is row into out in a frame
      # of the icon set: a top border, each code row past its two-column
      # indent cut into pieces of the inner width on a character boundary,
      # each piece between the sides and padded, its spans moved onto it,
      # a blank row inside the block a blank framed row, then a bottom
      # border, no row past row_limit. The inner width is the block's
      # widest code row, at most width - 4, so every row fits the width
      # and wrap leaves it whole. Returns the row after the block.
      #: (DocsText, Integer, Integer, DocsText, String, Integer) -> Integer
      def self.frame(doc, row, width, out, set, row_limit)
        fenced = doc.block(row)
        last = row
        inner = 1
        r = row
        while r < doc.count && (doc.block(r) == fenced || (doc.block(r) == 0 && doc.line(r).empty?))
          if doc.block(r) == fenced
            last = r
            cells = DisplayWidth.text_width(doc.line(r), 2)
            inner = cells if cells > inner
          end
          r += 1
        end
        inner = width - 4 if inner > width - 4
        box = box(set)
        widths = [inner]
        out.add_row(border(widths, box, BOX_TOP), "", 0)
        r = row
        while r <= last && out.count < row_limit
          frame_line(doc, r, inner, out, box, row_limit)
          r += 1
        end
        out.add_row(border(widths, box, BOX_BOTTOM), "", 0) if out.count < row_limit
        last + 1
      end

      # Adds the row of the document past its two-column indent to out as
      # framed rows of inner cells between the box's sides, cut on a
      # character boundary, its spans moved two columns in with each
      # piece; an empty row is one blank framed row.
      #: (DocsText, Integer, Integer, DocsText, Array[String], Integer) -> void
      def self.frame_line(doc, row, inner, out, box, row_limit)
        text = doc.line(row)
        syntax = doc.syntax(row)
        fenced = doc.block(row)
        side = box[BOX_SIDE]
        len = text.bytesize
        i = len < 2 ? len : 2
        col = i
        while out.count < row_limit
          used = 0
          stop = i
          stop_col = col
          while stop < len
            size = Utf8.size_at(text, stop, len)
            code = Utf8.code_at(text, stop, size)
            cells = DisplayWidth.control?(code) ? 1 : DisplayWidth.of(code)
            break if used + cells > inner && stop > i
            used += cells
            stop += size
            stop_col += 1
          end
          piece = +""
          piece << side
          piece << " "
          piece << text.byteslice(i, stop - i).to_s
          (inner - used).times { piece << " " }
          piece << " "
          piece << side
          at = out.add_row(piece, syntax, fenced)
          out.copy_spans(doc, row, col, stop_col, at, 2)
          return if stop >= len
          i = stop
          col = stop_col
        end
      end

      # The lines joined by newlines, at most limit bytes of them: a line
      # longer than the room left is read only up to it, cut back to a
      # character boundary, and nothing after it is read, so a huge line
      # costs no more than the reader reads.
      #: (Array[String], Integer) -> String
      def self.gather(lines, limit)
        out = +""
        row = 0
        while row < lines.length && out.bytesize < limit
          out << "\n" if row > 0
          line = lines[row]
          room = limit - out.bytesize
          if line.bytesize > room
            cut = room
            cut -= 1 while cut > 0 && (line.getbyte(cut).to_i & 0xC0) == 0x80
            out << line.byteslice(0, cut).to_s
            return out
          end
          out << line
          row += 1
        end
        out
      end

      # The byte after the table whose header is line and whose separator
      # row starts at byte start of body, its rows drawn into the document
      # at width cells, after a blank row when gap is set; -1, nothing
      # added, when the next line is no separator row of as many cells as
      # the header, and -2, nothing added, when it is one but the width
      # cannot give each column CELL_MIN cells, so parse keeps the header
      # and each line holding a pipe after it its own row, unflowed.
      # Its rows are the lines holding a pipe after the separator up to one
      # that opens another block, at most row_limit of them counted with
      # the header, and no row is added past row_limit.
      #: (String, Integer, String, DocsText, String, Integer, Integer, Integer, bool) -> Integer
      def self.table(body, start, line, doc, set, raw_limit, row_limit, width, gap)
        len = body.bytesize
        return -1 if start > len
        stop = line_end(body, start)
        aligns = alignments(ControlText.line(body.byteslice(start, stop - start).to_s, raw_limit))
        cols = aligns.length
        return -1 if cols == 0
        head = split_cells(line)
        return -1 unless head.length == cols
        return -2 if (CELL_MIN + 3) * cols + 1 > width
        scratch = DocsText.new
        cells = add_cells(head, cols, Array.new(0, ""), scratch)
        rows = 1
        start = stop + 1
        while start <= len && rows < row_limit
          stop = line_end(body, start)
          text = ControlText.line(body.byteslice(start, stop - start).to_s, raw_limit)
          break if !text.include?("|") || opens_block?(text)
          cells = add_cells(split_cells(text), cols, cells, scratch)
          rows += 1
          start = stop + 1
        end
        doc.add_row("", "", 0) if gap && doc.count < row_limit
        draw_table(cells, aligns, rows, doc, set, row_limit, width)
        start
      end

      # The byte of the line feed ending the line that starts at byte
      # start of body, or the body's end.
      #: (String, Integer) -> Integer
      def self.line_end(body, start)
        found = body.byteindex("\n", Utf8.boundary(body, start))
        found.nil? ? body.bytesize : found.to_i
      end

      # The cells of a table line, each stripped: cut at every pipe not
      # escaped as "\|", one leading and one trailing pipe dropped.
      #: (String) -> Array[String]
      def self.split_cells(line)
        out = Array.new(0, "")
        text = line.strip
        len = text.bytesize
        i = len > 0 && text.getbyte(0).to_i == 0x7C ? 1 : 0
        cell = +""
        tail = true
        while i < len
          b = text.getbyte(i).to_i
          if b == 0x7C
            out << cell.strip
            cell = +""
            tail = false
            i += 1
          else
            size = 1
            if b == 0x5C && text.getbyte(i + 1).to_i == 0x7C
              size = 2
            elsif b >= 0x80
              size = Utf8.size_at(text, i, len)
            end
            cell << text.byteslice(i, size).to_s
            tail = true
            i += size
          end
        end
        out << cell.strip if tail
        out
      end

      # The alignment of each cell of a separator row: ALIGN_LEFT for ---
      # or :--, ALIGN_CENTER for :-:, ALIGN_RIGHT for --:; none when the
      # line is no separator row, which holds a pipe and a hyphen and
      # nothing but spaces, pipes, colons, and hyphens, each cell hyphens
      # with an optional colon at either end.
      #: (String) -> Array[Integer]
      def self.alignments(line)
        out = Array.new(0, 0)
        return out unless line.include?("|") && line.include?("-")
        i = 0
        while i < line.bytesize
          b = line.getbyte(i).to_i
          return out unless b == 0x20 || b == 0x7C || b == 0x3A || b == 0x2D
          i += 1
        end
        cells = split_cells(line)
        c = 0
        while c < cells.length
          cell = cells[c]
          n = cell.bytesize
          left = n > 0 && cell.getbyte(0).to_i == 0x3A
          right = n > 1 && cell.getbyte(n - 1).to_i == 0x3A
          from = left ? 1 : 0
          to = right ? n - 1 : n
          return Array.new(0, 0) unless dashes?(cell, from, to)
          out << (left && right ? ALIGN_CENTER : (right ? ALIGN_RIGHT : ALIGN_LEFT))
          c += 1
        end
        out
      end

      # Whether the bytes [from, to) of the text are one or more hyphens
      # and nothing else.
      #: (String, Integer, Integer) -> bool
      def self.dashes?(text, from, to)
        return false unless to > from
        i = from
        while i < to
          return false unless text.getbyte(i).to_i == 0x2D
          i += 1
        end
        true
      end

      # The cells with cols cells of a table row added, their inline
      # markup read out (its spans going to scratch and dropped), a short
      # row padded with empty cells and a long one cut.
      #: (Array[String], Integer, Array[String], DocsText) -> Array[String]
      def self.add_cells(row, cols, cells, scratch)
        c = 0
        while c < cols
          cells << (c < row.length ? inline(row[c], 0, scratch, 0) : "")
          scratch.drop_spans(0)
          c += 1
        end
        cells
      end

      # Adds a table's rows, cols cells each in cells, to the document at
      # width cells: the top border, the header, a rule under it when body
      # rows follow, the body, and the bottom border, from the icon set,
      # while the document is under row_limit rows.
      #: (Array[String], Array[Integer], Integer, DocsText, String, Integer, Integer) -> void
      def self.draw_table(cells, aligns, rows, doc, set, row_limit, width)
        cols = aligns.length
        widths = column_widths(cells, cols, width)
        box = box(set)
        doc.add_row(border(widths, box, BOX_TOP), "", 0) if doc.count < row_limit
        r = 0
        while r < rows && doc.count < row_limit
          draw_row(cells, r * cols, aligns, widths, doc, box, row_limit)
          doc.add_row(border(widths, box, BOX_MIDDLE), "", 0) if r == 0 && rows > 1 && doc.count < row_limit
          r += 1
        end
        doc.add_row(border(widths, box, BOX_BOTTOM), "", 0) if doc.count < row_limit
      end

      # The text width of each of the cols columns: its widest cell, at
      # least CELL_MIN; when the table would be wider than width cells,
      # the columns are capped at the widest cap that fits, the room left
      # going a cell each to the capped columns in order, so the widest
      # columns give way first.
      #: (Array[String], Integer, Integer) -> Array[Integer]
      def self.column_widths(cells, cols, width)
        natural = Array.new(cols, CELL_MIN)
        i = 0
        while i < cells.length
          cell_width = DisplayWidth.text_width(cells[i], 0)
          natural[i % cols] = cell_width if cell_width > natural[i % cols]
          i += 1
        end
        room = width - 3 * cols - 1
        widest = CELL_MIN
        c = 0
        while c < cols
          widest = natural[c] if natural[c] > widest
          c += 1
        end
        return natural if capped_sum(natural, widest) <= room
        low = CELL_MIN
        high = widest
        while low < high
          mid = (low + high + 1) / 2
          if capped_sum(natural, mid) <= room
            low = mid
          else
            high = mid - 1
          end
        end
        out = Array.new(cols, 0)
        left = room
        c = 0
        while c < cols
          out[c] = natural[c] < low ? natural[c] : low
          left -= out[c]
          c += 1
        end
        c = 0
        while c < cols && left > 0
          if natural[c] > out[c]
            out[c] += 1
            left -= 1
          end
          c += 1
        end
        out
      end

      # The sum of the widths, each capped at cap.
      #: (Array[Integer], Integer) -> Integer
      def self.capped_sum(widths, cap)
        total = 0
        i = 0
        while i < widths.length
          total += widths[i] < cap ? widths[i] : cap
          i += 1
        end
        total
      end

      # Adds the lines of one table row, its cells from index first of
      # cells: as many as its tallest cell wraps to, each cell aligned in
      # its column and blank below its last piece, while the document is
      # under row_limit rows.
      #: (Array[String], Integer, Array[Integer], Array[Integer], DocsText, Array[String], Integer) -> void
      def self.draw_row(cells, first, aligns, widths, doc, box, row_limit)
        cols = aligns.length
        pieces = Array.new(0, "")
        starts = Array.new(0, 0)
        height = 1
        c = 0
        while c < cols
          starts << pieces.length
          lines = cell_lines(cells[first + c], widths[c], row_limit)
          height = lines.length if lines.length > height
          k = 0
          while k < lines.length
            pieces << lines[k]
            k += 1
          end
          c += 1
        end
        starts << pieces.length
        side = box[BOX_SIDE]
        line = 0
        while line < height && doc.count < row_limit
          out = +""
          out << side
          c = 0
          while c < cols
            at = starts[c] + line
            out << " "
            out << padded(at < starts[c + 1] ? pieces[at] : "", widths[c], aligns[c])
            out << " "
            out << side
            c += 1
          end
          doc.add_row(out, "", 0)
          line += 1
        end
      end

      # The text cut into pieces of at most width cells, each at its last
      # space within the width, or on a character when a word is longer,
      # at most limit of them; one empty piece for an empty text.
      #: (String, Integer, Integer) -> Array[String]
      def self.cell_lines(text, width, limit)
        out = Array.new(0, "")
        len = text.bytesize
        start = 0
        used = 0
        space = -1
        i = 0
        while i < len && out.length < limit
          size = Utf8.size_at(text, i, len)
          cells = DisplayWidth.of(Utf8.code_at(text, i, size))
          if used + cells > width && i > start
            cut = space > start ? space : i
            out << text.byteslice(start, cut - start).to_s.rstrip
            start = space > start ? space + 1 : i
            start += 1 while start < len && text.getbyte(start).to_i == 0x20
            i = start
            used = 0
            space = -1
            next
          end
          space = i if text.getbyte(i).to_i == 0x20
          used += cells
          i += size
        end
        out << text.byteslice(start, len - start).to_s if out.empty? || (start < len && out.length < limit)
        out
      end

      # The piece padded with spaces to width cells by its alignment, a
      # centered piece's odd cell on its right.
      #: (String, Integer, Integer) -> String
      def self.padded(piece, width, align)
        gap = width - DisplayWidth.text_width(piece, 0)
        gap = 0 if gap < 0
        left = 0
        left = gap if align == ALIGN_RIGHT
        left = gap / 2 if align == ALIGN_CENTER
        out = +""
        out << " " * left
        out << piece
        out << " " * (gap - left)
        out
      end

      # A border line of a table whose columns are widths wide: the left
      # corner or tee at index at of the box, the joint after it between
      # columns, the right one after that, the horizontal line between.
      #: (Array[Integer], Array[String], Integer) -> String
      def self.border(widths, box, at)
        out = +""
        out << box[at]
        c = 0
        while c < widths.length
          out << box[at + 1] if c > 0
          (widths[c] + 2).times { out << box[BOX_LINE] }
          c += 1
        end
        out << box[at + 2]
        out
      end

      # The table border pieces of the icon set: plain for "ascii", else
      # BOX.
      #: (String) -> Array[String]
      def self.box(set)
        set == "ascii" ? ASCII_BOX : BOX
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
      # markup taken out, its spans added to the document's row at, its
      # markers those of the icon set; a heading's span reaches the end of
      # a line of at most raw_limit bytes.
      #: (String, DocsText, Integer, String, Integer) -> String
      def self.block(line, doc, at, set, raw_limit)
        len = line.bytesize
        scan = markers(line)
        i = marker_stop(scan)
        depth = marker_depth(scan)
        indent = marker_indent(scan) / 2
        indent = NEST_LIMIT if indent > NEST_LIMIT
        out = +""
        depth.times { out << bar(set) }
        indent.times { out << "  " }
        rest = line.byteslice(i, len - i).to_s
        if rule?(rest)
          out << rule(set)
          return out
        end
        offset = (depth + indent) * 2
        heading = heading?(rest)
        rest = heading_text(rest)
        doc.add_span(at, offset, offset + raw_limit, Highlight::MARKUP_HEADING) if heading
        mark = rest.getbyte(0).to_i
        if (mark == 0x2D || mark == 0x2A || mark == 0x2B) && rest.getbyte(1).to_i == 0x20
          out << bullet(set)
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
            found = text.byteindex(")", Utf8.boundary(text, i + 2))
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

      # The list bullet of the icon set: plain for "ascii", else BULLET.
      #: (String) -> String
      def self.bullet(set)
        set == "ascii" ? ASCII_BULLET : BULLET
      end

      # The quote bar of the icon set: plain for "ascii", else BAR.
      #: (String) -> String
      def self.bar(set)
        set == "ascii" ? ASCII_BAR : BAR
      end

      # The thematic-break rule of the icon set: plain for "ascii", else
      # RULE.
      #: (String) -> String
      def self.rule(set)
        set == "ascii" ? ASCII_RULE : RULE
      end

      # The bytes of the row's prefix: its leading spaces, bars, and
      # bullet, those of the icon set.
      #: (String, String) -> Integer
      def self.prefix_size(row, set)
        len = row.bytesize
        bar = bar(set)
        bullet = bullet(set)
        i = 0
        while i < len
          if row.getbyte(i).to_i == 0x20
            i += 1
          elsif row.byteslice(i, bar.bytesize).to_s == bar
            i += bar.bytesize
          elsif row.byteslice(i, bullet.bytesize).to_s == bullet
            i += bullet.bytesize
          else
            return i
          end
        end
        i
      end

      # The prefix the continuation rows of a wrapped row start with: the
      # row's prefix, its leading spaces and bars kept and its bullet read
      # as two spaces, so the text hangs under its first word.
      #: (String, String) -> String
      def self.hang(prefix, set)
        bullet = bullet(set)
        out = +""
        len = prefix.bytesize
        i = 0
        while i < len
          if prefix.byteslice(i, bullet.bytesize).to_s == bullet
            out << "  "
            i += bullet.bytesize
          else
            size = Utf8.size_at(prefix, i, len)
            out << prefix.byteslice(i, size).to_s
            i += size
          end
        end
        out
      end

      # The rows with the document's row added, wrapped at width cells:
      # at its last space before the width that follows text of the
      # segment, or on a character boundary when it has none, each piece
      # with the row's spans cut to it. The row's prefix (its leading
      # spaces, bars, and bullet) is not text, so a code indent, a bullet,
      # or a bar is never left alone on a row; outside fenced code each
      # piece after the first starts with the prefix as hang gives it,
      # while that takes less than half the width.
      #: (DocsText, Integer, Integer, DocsText, String, Integer) -> DocsText
      def self.wrapped(doc, row, width, out, set, row_limit)
        text = doc.line(row)
        syntax = doc.syntax(row)
        fenced = doc.block(row)
        len = text.bytesize
        if len == 0
          out.add_row(text, syntax, fenced)
          return out
        end
        prefix = prefix_size(text, set)
        hanging = fenced == 0 ? hang(text.byteslice(0, prefix).to_s, set) : ""
        hang_cells = DisplayWidth.text_width(hanging, 0)
        if hang_cells * 2 >= width
          hanging = ""
          hang_cells = 0
        end
        hang_chars = char_count(hanging)
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
            piece = text.byteslice(start, cut - start).to_s.rstrip
            hung = start > 0 && !hanging.empty?
            at = out.add_row(hung ? hanging + piece : piece, syntax, fenced)
            out.copy_spans(doc, row, start_col, cut_col, at, hung ? hang_chars : 0)
            return out if out.count >= row_limit
            start = at_space ? space + 1 : i
            start_col = at_space ? space_col + 1 : col
            i = start
            col = start_col
            used = hang_cells
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
          piece = text.byteslice(start, len - start).to_s
          hung = start > 0 && !hanging.empty?
          at = out.add_row(hung ? hanging + piece : piece, syntax, fenced)
          out.copy_spans(doc, row, start_col, col, at, hung ? hang_chars : 0)
        end
        out
      end
    end
  end
end
