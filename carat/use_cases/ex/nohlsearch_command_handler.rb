require_relative "../../domain/editor_state"
require_relative "../../domain/last_search"
require_relative "../outcome"
require_relative "ex_handler"
require_relative "ex_table"

module Carat
  module UseCases
    # :noh[lsearch]: the matches of the last search are no longer
    # highlighted, until the next search, "n", or :set hlsearch shows
    # them again; the pattern stays for "n". No message.
    class NohlsearchCommandHandler < ExHandler
      attr_reader :last_search #: Domain::LastSearch

      #: (spec: String, last_search: Domain::LastSearch) -> void
      def initialize(spec:, last_search:)
        super(spec: spec)
        @last_search = last_search
      end

      # @rbs state: Domain::EditorState
      # @rbs command: Domain::ExCommand
      def call(state, command)
        @last_search.hide
        Outcome.none
      end

      # Registers :nohlsearch after :set.
      #: (ExTable, last_search: Domain::LastSearch) -> void
      def self.register(table, last_search:)
        table.register(NohlsearchCommandHandler.new(spec: "noh[lsearch]", last_search: last_search))
      end
    end
  end
end
