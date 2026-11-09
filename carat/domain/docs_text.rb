require_relative "syntax_line"

module Carat
  module Domain
    # Documentation laid out as rows with the spans of its markup: the
    # rows' text (texts); the spans as flat (row, start column, length, group id)
    # quads in code point columns, kept in the order they paint, so a
    # later span of a row is drawn over an earlier one; and per row the
    # language its fence names ("" outside fenced code or for a fence
    # that names none) and its fenced block's number (0 outside fenced
    # code). MarkdownText builds one and wraps it into another; styles
    # gives a buffer its rows' tokens. A Struct record.
    class DocsText < Struct.new(:texts, :spans, :syntaxes, :blocks, keyword_init: true)
      # @rbs @texts: Array[String]
      # @rbs @spans: Array[Integer]
      # @rbs @syntaxes: Array[String]
      # @rbs @blocks: Array[Integer]

      #: () -> void
      def initialize
        super()
        self.texts = []
        self.spans = Array.new(0, 0)
        self.syntaxes = []
        self.blocks = Array.new(0, 0)
      end

      # The number of rows.
      #: () -> Integer
      def count
        texts.length
      end

      #: (Integer) -> String
      def line(row)
        texts[row]
      end

      # The language the fence of a row's block names, "" for none.
      #: (Integer) -> String
      def syntax(row)
        syntaxes[row]
      end

      # The number of a row's fenced block, 0 outside fenced code.
      #: (Integer) -> Integer
      def block(row)
        blocks[row]
      end

      # Adds a row and returns its index.
      #: (String, String, Integer) -> Integer
      def add_row(text, syntax, block)
        texts << text
        syntaxes << syntax
        blocks << block
        texts.length - 1
      end

      # Adds a span of the row over the columns [from, to), when it holds
      # any.
      #: (Integer, Integer, Integer, Integer) -> void
      def add_span(row, from, to, group)
        return unless to > from
        spans << row
        spans << from
        spans << to - from
        spans << group
      end

      # Drops the spans of the rows from row on, which are the last ones
      # while rows are added in order.
      #: (Integer) -> void
      def drop_spans(row)
        while spans.length >= 4 && spans[spans.length - 4] >= row
          4.times { spans.pop }
        end
      end

      # Adds to row at the spans of the source's row cut to the columns
      # [from, to), moved to start at from.
      #: (DocsText, Integer, Integer, Integer, Integer) -> void
      def copy_spans(source, row, from, to, at)
        quads = source.spans
        i = 0
        while i + 3 < quads.length
          if quads[i] == row
            low = quads[i + 1]
            high = low + quads[i + 2]
            low = from if low < from
            high = to if high > to
            add_span(at, low - from, high - from, quads[i + 3]) if low < high
          end
          i += 4
        end
      end

      # Drops the empty rows at the end and their spans.
      #: () -> void
      def trim
        while !texts.empty? && texts[texts.length - 1].empty?
          texts.pop
          syntaxes.pop
          blocks.pop
        end
        drop_spans(texts.length)
      end

      # The spans of a row as (start column, length, group id) triples.
      #: (Integer) -> Array[Integer]
      def tokens_of(row)
        out = Array.new(0, 0)
        quads = spans
        i = 0
        while i + 3 < quads.length
          if quads[i] == row
            out << quads[i + 1]
            out << quads[i + 2]
            out << quads[i + 3]
          end
          i += 4
        end
        out
      end

      # A SyntaxLine per row, of the row's own string and its tokens, for
      # Buffer#styles.
      #: () -> Array[untyped]
      def styles
        out = Array.new(0, nil)
        row = 0
        while row < texts.length
          out << SyntaxLine.new(text: texts[row], start: 0, tokens: tokens_of(row), end_state: 0)
          row += 1
        end
        out
      end
    end
  end
end
