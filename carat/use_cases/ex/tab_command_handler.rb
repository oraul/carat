require_relative "../../domain/editor_state"
require_relative "../windows/open_tab"
require_relative "../windows/close_tab"
require_relative "../windows/close_other_tabs"
require_relative "../windows/switch_tab"
require_relative "../windows/tab_request"
require_relative "ex_handler"
require_relative "ex_table"

module Carat
  module UseCases
    # The ex commands of tab pages: :tabnew, :tabe, :tabc, :tabo, :tabn,
    # :tabp, :tabN, :tabfir, and :tabl.
    class TabCommandHandler < ExHandler
      # @rbs @open_tab: OpenTab
      # @rbs @close_tab: CloseTab
      # @rbs @close_other_tabs: CloseOtherTabs
      # @rbs @switch_tab: SwitchTab
      # @rbs @variant: Symbol

      #: (spec: String, open_tab: OpenTab, close_tab: CloseTab, close_other_tabs: CloseOtherTabs, switch_tab: SwitchTab, variant: Symbol) -> void
      def initialize(spec:, open_tab:, close_tab:, close_other_tabs:, switch_tab:, variant:)
        super(spec: spec)
        @open_tab = open_tab
        @close_tab = close_tab
        @close_other_tabs = close_other_tabs
        @switch_tab = switch_tab
        @variant = variant
      end

      # @rbs state: Domain::EditorState
      # @rbs command: Domain::ExCommand
      def call(state, command)
        case @variant
        when :open then @open_tab.call(state, command.args)
        when :close then @close_tab.call(state)
        when :only then @close_other_tabs.call(state)
        else @switch_tab.call(state, TabRequest.new(target: @variant, count: 0))
        end
      end

      # Registers the tab page commands in the order of
      # docs/compatibility.md.
      #: (ExTable, open_tab: OpenTab, close_tab: CloseTab, close_other_tabs: CloseOtherTabs, switch_tab: SwitchTab) -> void
      def self.register(table, open_tab:, close_tab:, close_other_tabs:, switch_tab:)
        specs = ["tabnew", "tabe[dit]", "tabc[lose]", "tabo[nly]", "tabn[ext]", "tabp[revious]", "tabN[ext]", "tabfir[st]", "tabl[ast]"]
        variants = [:open, :open, :close, :only, :next, :previous, :previous, :first, :last]
        i = 0
        while i < specs.length
          table.register(TabCommandHandler.new(spec: specs[i], open_tab: open_tab, close_tab: close_tab, close_other_tabs: close_other_tabs, switch_tab: switch_tab, variant: variants[i]))
          i += 1
        end
      end
    end
  end
end
