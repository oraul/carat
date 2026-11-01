require_relative "../windows/switch_tab"
require_relative "action_handler"
require_relative "action_table"

module Carat
  module UseCases
    # gt and gT with their counts, through SwitchTab.
    class TabHandler < ActionHandler
      # @rbs @switch_tab: SwitchTab
      # @rbs @forward: bool

      #: (switch_tab: SwitchTab, forward: bool) -> void
      def initialize(switch_tab:, forward:)
        super(kind: :action)
        @switch_tab = switch_tab
        @forward = forward
      end

      # @rbs state: Domain::EditorState
      # @rbs command: Domain::Command
      def call(state, command)
        return @switch_tab.next(state, command.count) if @forward
        @switch_tab.previous(state, command.count)
      end

      #: (ActionTable, switch_tab: SwitchTab) -> void
      def self.register(table, switch_tab:)
        table.register("tab.next", TabHandler.new(switch_tab: switch_tab, forward: true))
        table.register("tab.previous", TabHandler.new(switch_tab: switch_tab, forward: false))
      end
    end
  end
end
