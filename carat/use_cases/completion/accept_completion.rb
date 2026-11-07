require_relative "../../domain/editor_state"
require_relative "../../domain/completion_menu"
require_relative "../../domain/fuzzy_match"
require_relative "../../domain/last_change"
require_relative "../../domain/position"
require_relative "../../domain/range"
require_relative "../outcome"
require_relative "close_completion"

module Carat
  module UseCases
    # Puts the selected item's text in place of the typed part (Enter,
    # completion.insert) or of the whole word under the cursor (Tab,
    # completion.replace, the word characters after the cursor too), in
    # one replace inside the insert session, closes the popup, and leaves
    # the cursor after the text. LastChange notes a Backspace per typed
    # character taken out, a Delete per character after the cursor, and
    # the text, so the dot command makes the same edit.
    class AcceptCompletion
      attr_reader :menu #: Domain::CompletionMenu
      attr_reader :last_change #: Domain::LastChange
      attr_reader :close_completion #: CloseCompletion

      #: (menu: Domain::CompletionMenu, last_change: Domain::LastChange, close_completion: CloseCompletion) -> void
      def initialize(menu:, last_change:, close_completion:)
        @menu = menu
        @last_change = last_change
        @close_completion = close_completion
      end

      #: (Domain::EditorState, bool) -> Outcome
      def call(state, replace)
        menu = @menu
        return Outcome.none unless menu.showing?
        text = menu.chosen.text
        cursor = state.cursor
        row = menu.row
        start = menu.col
        stop = cursor.col
        line = state.buffer.line(row)
        after = 0
        if replace
          tail = line[stop, line.length - stop].to_s
          after = tail.byteslice(0, Domain::FuzzyMatch.word_length(tail)).to_s.length
        end
        from = Domain::Position.new(row: row, col: start)
        to = Domain::Position.new(row: row, col: stop + after)
        state.buffer.replace(Domain::Range.charwise(from, to), text)
        note(stop - start, after, text)
        cursor.move_to(row, start + text.length)
        @close_completion.call(state)
      end

      private

      #: (Integer, Integer, String) -> void
      def note(typed, after, text)
        i = 0
        while i < typed
          @last_change.add_action("insert.backspace", "", true)
          i += 1
        end
        i = 0
        while i < after
          @last_change.add_action("insert.delete", "", false)
          i += 1
        end
        @last_change.add_text(text)
      end
    end
  end
end
