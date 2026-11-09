require_relative "../../domain/editor_state"
require_relative "../../domain/completion_menu"
require_relative "../../domain/completion_list"
require_relative "../../domain/completion_request"
require_relative "../../domain/fuzzy_match"
require_relative "../../domain/display_width"
require_relative "../../domain/mode"
require_relative "../../ports/completion_port"
require_relative "close_completion"
require_relative "open_completion_popup"
require_relative "show_completion_docs"

module Carat
  module UseCases
    # Opens, filters, or closes the completion popup after a key in insert
    # mode. HandleKey calls it after a typed character (typed true) and
    # after any key while the popup shows. Without a popup it returns at
    # once unless a character was typed and the source is ready, so a
    # typed key costs no allocation otherwise. It reads the word before
    # the cursor, asks the source for its candidates when the word's
    # buffer, row, or start changed, and shows those matching the typed
    # part in the popup (OpenCompletionPopup), the first selected. An
    # unchanged typed part keeps the popup and its selection, an empty one
    # too when the popup was opened for an empty word (CompleteWord); an
    # empty word otherwise, no match, or another mode closes it, and so does a key that is not
    # typed text and leaves the word, such as one moving to another row
    # or buffer: only a typed character asks the source again, or an
    # answer the source's request marks arrived, which counts as typed.
    # Whenever it leaves the popup showing, ShowCompletionDocs shows the
    # selected candidate's documentation beside it; documentation the
    # request marks arrived refreshes it too.
    class ShowCompletion
      attr_reader :menu #: Domain::CompletionMenu
      attr_reader :source #: Ports::CompletionPort
      attr_reader :open_popup #: OpenCompletionPopup
      attr_reader :close_completion #: CloseCompletion
      attr_reader :show_docs #: ShowCompletionDocs

      #: (menu: Domain::CompletionMenu, source: Ports::CompletionPort, open_popup: OpenCompletionPopup, close_completion: CloseCompletion, show_docs: ShowCompletionDocs) -> void
      def initialize(menu:, source:, open_popup:, close_completion:, show_docs:)
        @menu = menu
        @source = source
        @open_popup = open_popup
        @close_completion = close_completion
        @show_docs = show_docs
      end

      #: (Domain::EditorState, bool) -> void
      def call(state, typed)
        menu = @menu
        showing = menu.showing?
        request = @source.request
        arrived = request.arrived
        docs = request.docs
        docs.arrived = false if docs.arrived
        return unless showing || arrived || (typed && @source.ready?(state.buffer))
        request.arrived = false if arrived
        refresh(state, menu, showing, typed || arrived)
        @show_docs.call(state) if menu.showing?
      end

      private

      # Opens, filters, or closes the popup; asked is whether a character
      # was typed or an answer arrived.
      #: (Domain::EditorState, Domain::CompletionMenu, bool, bool) -> void
      def refresh(state, menu, showing, asked)
        if state.mode != Domain::Mode::INSERT || (showing && state.tab.floats.index_of(menu.float_id) < 0)
          @close_completion.call(state)
          return
        end
        buffer = state.buffer
        cursor = state.cursor
        head = buffer.line(cursor.row)[0, cursor.col].to_s
        start = Domain::FuzzyMatch.word_start(head)
        prefix = head.byteslice(start, head.bytesize - start).to_s
        col = cursor.col - prefix.length
        same = menu.for_word?(buffer.id, cursor.row, col)
        if prefix.empty? && !(same && showing && menu.prefix.empty?)
          @close_completion.call(state)
          return
        end
        if same
          return if showing && prefix == menu.prefix
        else
          unless asked && @source.ready?(buffer)
            @close_completion.call(state)
            return
          end
          menu.fill(@source.candidates(buffer, cursor.row, col), buffer.id, cursor.row, col)
        end
        menu.prefix = prefix
        menu.matches = ranked(menu.candidates, prefix)
        if menu.matches.empty?
          @close_completion.call(state)
          return
        end
        menu.selected = 0
        @open_popup.call(state, Domain::DisplayWidth.text_width(prefix, 0))
      end

      # The indices of the candidates matching the prefix, the best score
      # first, equal scores in the source's order.
      #: (Domain::CompletionList, String) -> Array[Integer]
      def ranked(candidates, prefix)
        order = [0]
        order.clear
        scores = [0]
        scores.clear
        i = 0
        while i < candidates.count
          score = Domain::FuzzyMatch.score(prefix, candidates.at(i).label)
          if score >= 0
            j = scores.length
            j -= 1 while j > 0 && scores[j - 1] < score
            scores.insert(j, score)
            order.insert(j, i)
          end
          i += 1
        end
        order
      end
    end
  end
end
