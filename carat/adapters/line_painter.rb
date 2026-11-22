require_relative "../domain/frame"
require_relative "../domain/highlight"
require_relative "../domain/display_width"
require_relative "../domain/decoded_line"

module Carat
  module Adapters
    # Paints a decoded line into a frame row, the text cells a window row
    # and a float row share: its characters in Normal from a display
    # column (C0 controls as ^X, delete and C1 controls as <xx>), then its
    # tokens' groups plus a layer. It holds no state, so the frame
    # presenter and the float painter each keep one, and it allocates
    # nothing.
    class LinePainter
      # Paints the visible part of a decoded line from frame column col
      # over width cells: characters whose display columns fall inside
      # [left, left + width), C0 controls as ^X, delete and C1 controls as
      # <xx>, and blanks everywhere else, tabs included.
      #: (Domain::Frame, Integer, Integer, Domain::DecodedLine, Integer, Integer) -> void
      def paint_text(frame, frame_row, col, decoded, width, left)
        if decoded.plain
          paint_plain(frame, frame_row, col, decoded.text, width, left)
          return
        end
        codes = decoded.codes
        cols = decoded.cols
        n = codes.length
        limit = left + width
        filled = col
        k = left > 0 ? decoded.index_at(left) : 0
        while k < n
          dcol = cols[k]
          break if dcol >= limit
          w = cols[k + 1] - dcol
          code = codes[k]
          if dcol >= left && dcol + w <= limit && w > 0 && code != 9
            at = col + dcol - left
            frame.blank(frame_row, filled, at) if at > filled
            if code < 32
              frame.put_code(frame_row, at, 94, 1, Domain::Highlight::NORMAL)
              frame.put_code(frame_row, at + 1, code + 64, 1, Domain::Highlight::NORMAL)
            elsif w == 4 && Domain::DisplayWidth.control?(code)
              frame.put_code(frame_row, at, 60, 1, Domain::Highlight::NORMAL)
              frame.put_code(frame_row, at + 1, hex_digit(code >> 4), 1, Domain::Highlight::NORMAL)
              frame.put_code(frame_row, at + 2, hex_digit(code & 15), 1, Domain::Highlight::NORMAL)
              frame.put_code(frame_row, at + 3, 62, 1, Domain::Highlight::NORMAL)
            else
              frame.put_code(frame_row, at, code, w, Domain::Highlight::NORMAL)
            end
            filled = at + w
          end
          k += 1
        end
        frame.blank(frame_row, filled, col + width) if filled < col + width
      end

      # Gives the cells of each token the token's group plus the layer: the
      # display columns of its code points inside [left, left + width), a
      # token past the end of the line cut there; when plain (NO_COLOR) only
      # the tokens in Highlight.plain_style? groups, a selected row's bar and
      # label, are painted.
      #: (Domain::Frame, Integer, Integer, Domain::DecodedLine, Integer, Integer, Array[Integer], Integer, bool) -> void
      def paint_tokens(frame, frame_row, col, decoded, width, left, tokens, layer, plain)
        size = decoded.size
        limit = left + width
        i = 0
        while i + 2 < tokens.length
          from = tokens[i]
          if from < size && (!plain || Domain::Highlight.plain_style?(tokens[i + 2]))
            to = from + tokens[i + 1]
            to = size if to > size
            first = decoded.col(from)
            last = decoded.col(to)
            first = left if first < left
            last = limit if last > limit
            frame.fill(frame_row, col + first - left, col + last - left, tokens[i + 2] + layer) if first < last
          end
          i += 3
        end
      end

      private

      # paint_text for a line of printable ASCII: one cell per byte.
      #: (Domain::Frame, Integer, Integer, String, Integer, Integer) -> void
      def paint_plain(frame, frame_row, col, text, width, left)
        n = text.bytesize
        k = left
        stop = left + width
        stop = n if stop > n
        at = col
        while k < stop
          frame.put_code(frame_row, at, text.getbyte(k).to_i, 1, Domain::Highlight::NORMAL)
          k += 1
          at += 1
        end
        frame.blank(frame_row, at, col + width) if at < col + width
      end

      # The code point of a lowercase hexadecimal digit.
      #: (Integer) -> Integer
      def hex_digit(value)
        value < 10 ? 48 + value : 87 + value
      end
    end
  end
end
