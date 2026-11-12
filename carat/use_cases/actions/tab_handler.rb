require_relative "../../domain/editor_state"
require_relative "../windows/switch_tab"
require_relative "../windows/tab_request"
require_relative "../buffers/switch_buffer"
require_relative "../buffers/buffer_request"
require_relative "action_handler"
require_relative "action_table"

module Carat
  module UseCases
    # The tab keys with their counts: the tab-page actions <C-PageDown>,
    # <C-PageUp>, and g<Tab> bind, through SwitchTab, and the tabline
    # actions gt and gT bind, which follow the buffer tabs through
    # SwitchBuffer under option.gt buffers, {count}gt the count-th tab,
    # and the tab pages as Vim's gt and gT under option.gt tabpages.
    class TabHandler < ActionHandler
      # @rbs @switch_tab: SwitchTab
      # @rbs @switch_buffer: SwitchBuffer
      # @rbs @target: Symbol
      # @rbs @tabline: bool

      #: (switch_tab: SwitchTab, switch_buffer: SwitchBuffer, target: Symbol, tabline: bool) -> void
      def initialize(switch_tab:, switch_buffer:, target:, tabline:)
        super(kind: :action, repeat: false)
        @switch_tab = switch_tab
        @switch_buffer = switch_buffer
        @target = target
        @tabline = tabline
      end

      # @rbs state: Domain::EditorState
      # @rbs command: Domain::Command
      def call(state, command)
        count = command.count
        return @switch_tab.call(state, TabRequest.new(target: @target, count: count)) unless @tabline && state.options.gt_follows_buffers?
        return @switch_buffer.call(state, BufferRequest.new(target: :tab, count: count, bang: false)) if @target == :next && count > 0
        @switch_buffer.call(state, BufferRequest.new(target: @target, count: count == 0 ? 1 : count, bang: false))
      end

      #: (ActionTable, switch_tab: SwitchTab, switch_buffer: SwitchBuffer) -> void
      def self.register(table, switch_tab:, switch_buffer:)
        names = ["tab.next", "tab.previous", "tab.last_accessed", "tabline.next", "tabline.previous"]
        targets = [:next, :previous, :last_accessed, :next, :previous]
        descriptions = ["Next tab page", "Previous tab page", "Last accessed tab page", "Next buffer tab or tab page", "Previous buffer tab or tab page"]
        i = 0
        while i < names.length
          table.register(names[i], TabHandler.new(switch_tab: switch_tab, switch_buffer: switch_buffer, target: targets[i], tabline: i > 2), descriptions[i])
          i += 1
        end
      end
    end
  end
end
