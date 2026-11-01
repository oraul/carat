require_relative "../../domain/editor_state"
require_relative "../../domain/tab_list"
require_relative "../outcome"

module Carat
  module UseCases
    # Moves between tab pages: next and previous with wrapping and counts,
    # as gt and gT and the :tab commands do, and first and last.
    class SwitchTab
      attr_reader :tabs #: Domain::TabList

      #: (tabs: Domain::TabList) -> void
      def initialize(tabs:)
        @tabs = tabs
      end

      # count 0 goes to the next tab page, wrapping; otherwise to tab page
      # number count, doing nothing when there is no such tab page.
      #: (Domain::EditorState, Integer) -> Outcome
      def next(state, count)
        @tabs.next_tab(count)
        Outcome.success("")
      end

      # Goes count tab pages back (at least one), wrapping.
      #: (Domain::EditorState, Integer) -> Outcome
      def previous(state, count)
        @tabs.previous_tab(count)
        Outcome.success("")
      end

      #: (Domain::EditorState) -> Outcome
      def first(state)
        @tabs.tab_index = 0
        Outcome.success("")
      end

      #: (Domain::EditorState) -> Outcome
      def last(state)
        @tabs.tab_index = @tabs.tab_count - 1
        Outcome.success("")
      end
    end
  end
end
