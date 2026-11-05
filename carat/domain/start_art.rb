require_relative "frame"
require_relative "highlight"

module Carat
  module Domain
    # The start screen's pictures, computed once when the screen starts: six
    # frames of a HEIGHT by WIDTH canvas, a code point and a highlight group
    # per cell (code 0 for a cell left blank), and the wordmark's one row
    # for a window too small for the canvas. The gem comes from GEM, whose
    # letters name an edge or a facet, each revealed at its stage: the
    # point alone in frame 0, the table in 1, the crown in 2, the pavilion
    # in 3, the sparkle in 4, and the wordmark and the key hints in 5. A
    # plain picture, for NO_COLOR, draws ASCII glyphs in the Normal group;
    # the other draws Unicode blocks and triangles in the theme's groups.
    # Every glyph takes one cell. A Data value.
    class StartArt < Data.define(:codes, :hls, :mark_codes, :mark_hls)
      # @rbs @codes: Array[Integer]
      # @rbs @hls: Array[Integer]
      # @rbs @mark_codes: Array[Integer]
      # @rbs @mark_hls: Array[Integer]

      FRAMES = 6
      LAST = 5
      HEIGHT = 15
      WIDTH = 20

      # The gem, its top row on canvas row GEM_TOP and its left column on
      # canvas column GEM_LEFT: / and \ are the crown's edges, L and R the
      # pavilion's, V the culet; a, b, and c are the crown's left facet,
      # table, and right facet, d, f, and e the pavilion's left, centre,
      # and right facets.
      GEM = [
        "    /bbbbbbb\\    ",
        "  /aaabbbbbccc\\  ",
        "/aaaaaabbbcccccc\\",
        "LddddddfffeeeeeeR",
        "  LddddfffeeeeR  ",
        "    LddfffeeR    ",
        "      LfffR      ",
        "        V        "
      ]
      GEM_TOP = 1
      GEM_LEFT = 1

      # The legend's bytes, and per entry the Unicode glyph, the ASCII
      # glyph, the group, and the frame it appears in.
      LEGEND = [47, 92, 76, 82, 86, 97, 98, 99, 100, 101, 102]
      GLYPHS = [0x25E2, 0x25E3, 0x25E5, 0x25E4, 0x25BC, 0x2588, 0x2588, 0x2588, 0x2588, 0x2588, 0x2588]
      PLAIN_GLYPHS = [47, 92, 92, 47, 118, 58, 61, 58, 46, 46, 124]
      GROUPS = [
        Highlight::FUNCTION, Highlight::KEYWORD, Highlight::KEYWORD, Highlight::FUNCTION, Highlight::OPERATOR,
        Highlight::FUNCTION, Highlight::OPERATOR, Highlight::KEYWORD, Highlight::KEYWORD, Highlight::FUNCTION, Highlight::OPERATOR
      ]
      STAGES = [2, 2, 3, 3, 3, 2, 1, 2, 3, 3, 3]

      POINT_ROW = 4
      POINT_COL = 9
      POINT = 0x2022
      SPARKLE_ROW = 0
      SPARKLE_COL = 14
      SPARKLE = 0x2726
      SPARKLE_FRAME = 4
      WORDMARK = "c a r a t"
      WORDMARK_ROW = 10
      HINT_ROW = 12
      HINT_KEY_WIDTH = 9
      HINTS = ["i", "insert text", ":e file", "open a file", ":q", "quit"]
      ASCII_POINT = 46
      ASCII_SPARKLE = 42

      # The six frames and the wordmark, in ASCII and Normal when plain.
      #: (bool) -> StartArt
      def self.build(plain)
        size = HEIGHT * WIDTH
        codes = Array.new(FRAMES * size, 0)
        hls = Array.new(FRAMES * size, Highlight::NORMAL)
        StartArt.place(codes, hls, POINT_ROW * WIDTH + POINT_COL, plain ? ASCII_POINT : POINT, plain ? Highlight::NORMAL : Highlight::TYPE)
        frame = 1
        while frame < FRAMES
          base = frame * size
          StartArt.draw_gem(codes, hls, base, frame, plain)
          if frame >= SPARKLE_FRAME
            StartArt.place(codes, hls, base + SPARKLE_ROW * WIDTH + SPARKLE_COL, plain ? ASCII_SPARKLE : SPARKLE, plain ? Highlight::NORMAL : Highlight::TYPE)
          end
          frame += 1
        end
        base = LAST * size
        StartArt.write(codes, hls, base + WORDMARK_ROW * WIDTH + (WIDTH - WORDMARK.length) / 2, WORDMARK, plain ? Highlight::NORMAL : Highlight::TITLE)
        i = 0
        while i + 1 < HINTS.length
          start = base + (HINT_ROW + i / 2) * WIDTH
          StartArt.write(codes, hls, start, HINTS[i], plain ? Highlight::NORMAL : Highlight::SPECIAL)
          StartArt.write(codes, hls, start + HINT_KEY_WIDTH, HINTS[i + 1], plain ? Highlight::NORMAL : Highlight::COMMENT)
          i += 2
        end
        mark_codes = Array.new(WORDMARK.length, 0)
        mark_hls = Array.new(WORDMARK.length, Highlight::NORMAL)
        StartArt.write(mark_codes, mark_hls, 0, WORDMARK, plain ? Highlight::NORMAL : Highlight::TITLE)
        StartArt.new(codes: codes, hls: hls, mark_codes: mark_codes, mark_hls: mark_hls)
      end

      # A picture with no cells, the start screen's before it starts.
      #: () -> StartArt
      def self.none
        StartArt.new(codes: [], hls: [], mark_codes: [], mark_hls: [])
      end

      # The gem's cells revealed by frame, written into the frame's part
      # of the canvas from base.
      #: (Array[Integer], Array[Integer], Integer, Integer, bool) -> void
      def self.draw_gem(codes, hls, base, frame, plain)
        r = 0
        while r < GEM.length
          line = GEM[r]
          c = 0
          while c < line.bytesize
            entry = LEGEND.index(line.getbyte(c).to_i)
            if !entry.nil? && STAGES[entry] <= frame
              index = base + (GEM_TOP + r) * WIDTH + GEM_LEFT + c
              StartArt.place(codes, hls, index, plain ? PLAIN_GLYPHS[entry] : GLYPHS[entry], plain ? Highlight::NORMAL : GROUPS[entry])
            end
            c += 1
          end
          r += 1
        end
      end

      # ASCII text from index, its spaces left blank.
      #: (Array[Integer], Array[Integer], Integer, String, Integer) -> void
      def self.write(codes, hls, index, text, hl)
        i = 0
        while i < text.bytesize
          byte = text.getbyte(i).to_i
          StartArt.place(codes, hls, index + i, byte, hl) unless byte == 32
          i += 1
        end
      end

      #: (Array[Integer], Array[Integer], Integer, Integer, Integer) -> void
      def self.place(codes, hls, index, code, hl)
        codes[index] = code
        hls[index] = hl
      end

      # Blanks the rectangle and draws frame step centred in it, or the
      # wordmark alone on its middle row when the canvas does not fit,
      # cut at the rectangle's right edge.
      #: (Frame, Integer, Integer, Integer, Integer, Integer) -> void
      def paint(frame, step, top, left, height, width)
        r = 0
        while r < height
          frame.blank(top + r, left, left + width)
          r += 1
        end
        return if codes.empty?
        step = 0 if step < 0
        step = LAST if step > LAST
        if height >= HEIGHT && width >= WIDTH
          copy(frame, codes, hls, step * HEIGHT * WIDTH, HEIGHT, WIDTH, top + (height - HEIGHT) / 2, left + (width - WIDTH) / 2, left + width)
        else
          length = mark_codes.length
          col = width > length ? left + (width - length) / 2 : left
          copy(frame, mark_codes, mark_hls, 0, 1, length, top + (height - 1) / 2, col, left + width)
        end
      end

      private

      # Copies rows by cols cells from index from, skipping blank ones and
      # those at or past column limit.
      #: (Frame, Array[Integer], Array[Integer], Integer, Integer, Integer, Integer, Integer, Integer) -> void
      def copy(frame, cells, groups, from, rows, cols, row, col, limit)
        r = 0
        while r < rows
          c = 0
          while c < cols && col + c < limit
            code = cells[from + r * cols + c]
            frame.put_code(row + r, col + c, code, 1, groups[from + r * cols + c]) if code != 0
            c += 1
          end
          r += 1
        end
      end
    end
  end
end
