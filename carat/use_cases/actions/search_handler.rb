require_relative "../../domain/search"
require_relative "../search/jump_to_match"
require_relative "action_handler"
require_relative "action_table"

module Carat
  module UseCases
    # The search actions: "/" and "?" (kind :search, which the grammar
    # finishes with the pattern typed at the prompt) and "n", "N", "*",
    # "#", "g*", and "g#" (kind :motion), each moving the cursor through
    # JumpToMatch. Under an operator the dispatcher runs the operator's
    # handler instead, whose Operate reads the search from the command.
    class SearchHandler < ActionHandler
      # @rbs @jump_to_match: JumpToMatch

      #: (jump_to_match: JumpToMatch, kind: Symbol) -> void
      def initialize(jump_to_match:, kind:)
        super(kind: kind, repeat: false)
        @jump_to_match = jump_to_match
      end

      # @rbs state: Domain::EditorState
      # @rbs command: Domain::Command
      def call(state, command)
        @jump_to_match.call(state, command)
      end

      # Registers Domain::Search::PROMPT_NAMES with the kind :search and
      # MOTION_NAMES with the kind :motion.
      #: (ActionTable, jump_to_match: JumpToMatch) -> void
      def self.register(table, jump_to_match:)
        prompt = SearchHandler.new(jump_to_match: jump_to_match, kind: :search)
        names = Domain::Search::PROMPT_NAMES
        i = 0
        while i < names.length
          table.register(names[i], prompt)
          i += 1
        end
        motion = SearchHandler.new(jump_to_match: jump_to_match, kind: :motion)
        names = Domain::Search::MOTION_NAMES
        i = 0
        while i < names.length
          table.register(names[i], motion)
          i += 1
        end
      end
    end
  end
end
