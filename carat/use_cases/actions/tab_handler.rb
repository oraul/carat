require_relative "../windows/switch_tab"
require_relative "../windows/tab_request"
require_relative "action_handler"
require_relative "action_table"

module Carat
  module UseCases
    # gt and gT with their counts, through SwitchTab.
    class TabHandler < ActionHandler
      # @rbs @switch_tab: SwitchTab
      # @rbs @target: Symbol

      #: (switch_tab: SwitchTab, target: Symbol) -> void
      def initialize(switch_tab:, target:)
        super(kind: :action, repeat: false)
        @switch_tab = switch_tab
        @target = target
      end

      # @rbs state: Domain::EditorState
      # @rbs command: Domain::Command
      def call(state, command)
        @switch_tab.call(state, TabRequest.new(target: @target, count: command.count))
      end

      #: (ActionTable, switch_tab: SwitchTab) -> void
      def self.register(table, switch_tab:)
        table.register("tab.next", TabHandler.new(switch_tab: switch_tab, target: :next), "Next tab page")
        table.register("tab.previous", TabHandler.new(switch_tab: switch_tab, target: :previous), "Previous tab page")
      end
    end
  end
end
