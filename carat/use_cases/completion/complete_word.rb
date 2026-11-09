require_relative "../../domain/editor_state"
require_relative "../../domain/buffer_list"
require_relative "../../domain/buffer_words"
require_relative "../../domain/completion_menu"
require_relative "../../domain/completion_list"
require_relative "../../domain/completion_item"
require_relative "../../domain/fuzzy_match"
require_relative "../../domain/display_width"
require_relative "../outcome"
require_relative "close_completion"
require_relative "open_completion_popup"

module Carat
  module UseCases
    # Neovim's keyword completion, Ctrl-N (forward true) and Ctrl-P in
    # insert mode with no popup showing: the words of the listed buffers
    # that complete the word before the cursor (BufferWords, in the order
    # it finds them) open the completion popup, whose keys then move,
    # accept, and close as for a source's candidates. Forward, the nearest
    # match is the first row and selected; backward, the matches are
    # listed in reverse, so the nearest is the last row and selected and
    # Ctrl-P moves on to the farther ones above it. No match leaves the
    # text and the mode and reports NOT_FOUND as an error.
    class CompleteWord
      NOT_FOUND = "Pattern not found"
      private_constant :NOT_FOUND

      attr_reader :menu #: Domain::CompletionMenu
      attr_reader :buffers #: Domain::BufferList
      attr_reader :open_popup #: OpenCompletionPopup
      attr_reader :close_completion #: CloseCompletion

      #: (menu: Domain::CompletionMenu, buffers: Domain::BufferList, open_popup: OpenCompletionPopup, close_completion: CloseCompletion) -> void
      def initialize(menu:, buffers:, open_popup:, close_completion:)
        @menu = menu
        @buffers = buffers
        @open_popup = open_popup
        @close_completion = close_completion
      end

      #: (Domain::EditorState, bool) -> Outcome
      def call(state, forward)
        menu = @menu
        @close_completion.call(state) if menu.showing?
        buffer = state.buffer
        cursor = state.cursor
        head = buffer.line(cursor.row)[0, cursor.col].to_s
        start = Domain::FuzzyMatch.word_start(head)
        prefix = head.byteslice(start, head.bytesize - start).to_s
        found = Domain::BufferWords.new(prefix: prefix)
        found.collect(@buffers, buffer, cursor.row, start, forward)
        words = found.words
        return Outcome.failure(NOT_FOUND) if words.empty?
        menu.fill(listed(words, forward), buffer.id, cursor.row, cursor.col - prefix.length)
        menu.prefix = prefix
        count = menu.candidates.count
        matches = [0]
        matches.clear
        i = 0
        while i < count
          matches << i
          i += 1
        end
        menu.matches = matches
        menu.selected = forward ? 0 : count - 1
        @open_popup.call(state, Domain::DisplayWidth.text_width(prefix, 0))
        Outcome.none
      end

      private

      # The words as candidates of kind text, in reverse order backward.
      #: (Array[String], bool) -> Domain::CompletionList
      def listed(words, forward)
        list = Domain::CompletionList.new
        count = words.length
        i = 0
        while i < count
          word = forward ? words[i] : words[count - 1 - i]
          list.add(Domain::CompletionItem.new(label: word, kind: "text", detail: "", text: word))
          i += 1
        end
        list
      end
    end
  end
end
