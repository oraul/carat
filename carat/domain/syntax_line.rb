module Carat
  module Domain
    # The tokens of one line as a tokenizer gave them for one start state:
    # the line string (kept, so a cache can compare by identity), the
    # state at the start of the line, the tokens as flat (start column,
    # length, group id) triples in code point columns, and the state at
    # the end of the line. A Data value, never changed after it is built.
    class SyntaxLine < Data.define(:text, :start, :tokens, :end_state)
      # The entry a row without highlighting is painted with.
      NONE = SyntaxLine.new(String.new("none"), -1, Array.new(0, 0), -1)

      # @rbs @text: String
      # @rbs @start: Integer
      # @rbs @tokens: Array[Integer]
      # @rbs @end_state: Integer

      # The number of tokens.
      #: () -> Integer
      def size
        tokens.length / 3
      end
    end
  end
end
