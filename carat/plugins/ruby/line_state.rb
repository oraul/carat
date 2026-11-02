module Carat
  module Plugins
    module Ruby
      # The state at the end of a line, packed into one integer of at most
      # 58 bits so the editor can compare and keep it:
      #
      #   bits 0-1    mode: CODE, EMBDOC (inside =begin), or DATA (after __END__)
      #   bits 2-3    pending heredocs, 0 to 2
      #   bits 4-13   the first heredoc, bits 14-23 the second: terminator
      #               number (1-255, in the tokenizer's table), indented
      #               (<<- or <<~), raw (single-quoted)
      #   bits 24-25  open string frames, 0 to 2
      #   bits 26-41  the outermost frame, bits 42-57 the next: closing
      #               delimiter byte (7 bits), interpolating, kind (string,
      #               symbol, regular expression), nesting depth of a paired
      #               delimiter (0-7), inside an interpolation, brace depth
      #               in it (0-3)
      #
      # What does not fit (a third frame or heredoc, a deeper nesting) is
      # dropped by the tokenizer before packing, the outermost kept.
      module LineState
        CODE = 0
        EMBDOC = 1
        DATA = 2

        MAX_HEREDOCS = 2
        MAX_FRAMES = 2
        MAX_TERMINATORS = 255
        MAX_DEPTH = 7
        MAX_BRACES = 3

        HEREDOC_BITS = 10
        FRAME_BITS = 16
        HEREDOC_SHIFT = 4
        FRAME_COUNT_SHIFT = 24
        FRAME_SHIFT = 26

        #: (Integer) -> Integer
        def self.mode(state)
          state & 3
        end

        #: (Integer) -> Integer
        def self.heredoc_count(state)
          (state >> 2) & 3
        end

        # The 10 bits of heredoc i.
        #: (Integer, Integer) -> Integer
        def self.heredoc(state, i)
          (state >> (HEREDOC_SHIFT + i * HEREDOC_BITS)) & 0x3FF
        end

        #: (Integer) -> Integer
        def self.frame_count(state)
          (state >> FRAME_COUNT_SHIFT) & 3
        end

        # The 16 bits of frame i, outermost first.
        #: (Integer, Integer) -> Integer
        def self.frame(state, i)
          (state >> (FRAME_SHIFT + i * FRAME_BITS)) & 0xFFFF
        end

        #: (Integer, Integer, Integer) -> Integer
        def self.pack_heredoc(term, indent, raw)
          term | (indent << 8) | (raw << 9)
        end

        #: (Integer, Integer, Integer, Integer, Integer, Integer) -> Integer
        def self.pack_frame(close, interp, kind, depth, in_code, braces)
          close | (interp << 7) | (kind << 8) | (depth << 10) | (in_code << 13) | (braces << 14)
        end

        #: (Integer) -> Integer
        def self.term_of(bits)
          bits & 255
        end

        #: (Integer) -> Integer
        def self.indent_of(bits)
          (bits >> 8) & 1
        end

        #: (Integer) -> Integer
        def self.raw_of(bits)
          (bits >> 9) & 1
        end

        #: (Integer) -> Integer
        def self.close_of(bits)
          bits & 127
        end

        #: (Integer) -> Integer
        def self.interp_of(bits)
          (bits >> 7) & 1
        end

        #: (Integer) -> Integer
        def self.kind_of(bits)
          (bits >> 8) & 3
        end

        #: (Integer) -> Integer
        def self.depth_of(bits)
          (bits >> 10) & 7
        end

        #: (Integer) -> Integer
        def self.code_of(bits)
          (bits >> 13) & 1
        end

        #: (Integer) -> Integer
        def self.braces_of(bits)
          (bits >> 14) & 3
        end

        # Packs a whole state from its parts: the mode, the pending heredocs
        # and the frames given as packed bits.
        #: (Integer, Integer, Integer, Integer, Integer, Integer, Integer) -> Integer
        def self.pack(mode, heredocs, first_heredoc, second_heredoc, frames, first_frame, second_frame)
          mode | (heredocs << 2) | (first_heredoc << HEREDOC_SHIFT) | (second_heredoc << (HEREDOC_SHIFT + HEREDOC_BITS)) |
            (frames << FRAME_COUNT_SHIFT) | (first_frame << FRAME_SHIFT) | (second_frame << (FRAME_SHIFT + FRAME_BITS))
        end
      end
    end
  end
end
