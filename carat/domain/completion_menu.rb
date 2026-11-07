require_relative "completion_list"
require_relative "completion_item"

module Carat
  module Domain
    # The completion popup's state, one per editor: the candidates the
    # source gave for the word that starts at col on row of the buffer
    # with buffer_id, cleaned; the typed part they were matched against;
    # the indices of the matching candidates in order (matches); the
    # selected one's position in matches; and the id of the float that
    # shows them, 0 when no popup shows. A Struct record: mutable, with a
    # reader and a writer per member.
    class CompletionMenu < Struct.new(:candidates, :matches, :selected, :buffer_id, :row, :col, :prefix, :float_id, keyword_init: true)
      # @rbs @candidates: CompletionList
      # @rbs @matches: Array[Integer]
      # @rbs @selected: Integer
      # @rbs @buffer_id: Integer
      # @rbs @row: Integer
      # @rbs @col: Integer
      # @rbs @prefix: String
      # @rbs @float_id: Integer

      #: () -> void
      def initialize
        super()
        self.candidates = CompletionList.new
        self.matches = []
        self.selected = 0
        self.buffer_id = 0
        self.row = -1
        self.col = -1
        self.prefix = ""
        self.float_id = 0
      end

      # Whether the popup shows.
      #: () -> bool
      def showing?
        float_id != 0
      end

      # Whether the candidates are for the word at col on row of the
      # buffer.
      #: (Integer, Integer, Integer) -> bool
      def for_word?(id, at_row, at_col)
        buffer_id == id && row == at_row && col == at_col
      end

      # Keeps the source's candidates for the word, each cleaned.
      #: (CompletionList, Integer, Integer, Integer) -> void
      def fill(list, id, at_row, at_col)
        kept = candidates
        kept.clear
        i = 0
        while i < list.count
          item = list.at(i)
          kept.add(CompletionItem.from_source(item.label, item.kind, item.detail, item.text))
          i += 1
        end
        self.buffer_id = id
        self.row = at_row
        self.col = at_col
        self.prefix = ""
      end

      # The selected candidate.
      #: () -> CompletionItem
      def chosen
        candidates.at(matches[selected])
      end

      # Forgets the candidates and the popup.
      #: () -> void
      def clear
        candidates.clear
        matches.clear
        self.selected = 0
        self.buffer_id = 0
        self.row = -1
        self.col = -1
        self.prefix = ""
        self.float_id = 0
      end
    end
  end
end
