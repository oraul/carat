require_relative "../../domain/editor_state"
require_relative "../../domain/tab_list"
require_relative "../outcome"
require_relative "tab_request"

module Carat
  module UseCases
    # Moves between tab pages as the request says: next and previous with
    # wrapping and counts, as <C-PageDown> and <C-PageUp> and the :tab
    # commands do, first and last, and the last accessed, as g<Tab> does.
    class SwitchTab
      attr_reader :tabs #: Domain::TabList

      #: (tabs: Domain::TabList) -> void
      def initialize(tabs:)
        @tabs = tabs
      end

      #: (Domain::EditorState, TabRequest) -> Outcome
      def call(state, request)
        case request.target
        when :next then @tabs.next_tab(request.count)
        when :previous then @tabs.previous_tab(request.count)
        when :first then @tabs.visit(0)
        when :last_accessed then @tabs.last_accessed_tab
        else @tabs.visit(@tabs.tab_count - 1)
        end
        Outcome.success("")
      end
    end
  end
end
