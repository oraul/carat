require_relative "keywords"
require_relative "tokenizer"

module Carat
  module Plugins
    module Ruby
      # Finds the block opener a Ruby text leaves open, without a language
      # server: a tokenizer of its own, whose ids are all -1 so it emits no
      # token, reads the lines from state 0, and each line's counts drive a
      # stack of opener rows, its ends popping (never below empty) and its
      # opens pushing the line's row.
      class Structure
        # @rbs @tokenizer: Tokenizer
        # @rbs @tokens: Array[Integer]
        # @rbs @rows: Array[Integer]

        #: (keywords: Keywords) -> void
        def initialize(keywords:)
          @tokenizer = Tokenizer.new(keywords: keywords)
          @tokens = Array.new(0, 0)
          @rows = Array.new(0, 0)
        end

        # The row of the innermost opener no end closes, -1 when every
        # opener is closed.
        #: (Array[String]) -> Integer
        def call(lines)
          rows = @rows
          rows.clear
          state = 0
          row = 0
          while row < lines.length
            state = @tokenizer.call(lines[row], state, @tokens)
            ends = @tokenizer.ends
            while ends > 0 && !rows.empty?
              rows.pop
              ends -= 1
            end
            opens = @tokenizer.opens
            while opens > 0
              rows << row
              opens -= 1
            end
            row += 1
          end
          rows.empty? ? -1 : rows[rows.length - 1]
        end
      end
    end
  end
end
