require_relative "../../domain/editor_state"
require_relative "../../domain/messages"
require_relative "../windows/open_tab"
require_relative "../windows/close_tab"
require_relative "../windows/close_other_tabs"
require_relative "../windows/switch_tab"
require_relative "../windows/tab_request"
require_relative "../outcome"
require_relative "ex_handler"
require_relative "ex_table"

module Carat
  module UseCases
    # The ex commands of tab pages: :tabnew and :tabe with a file; :tabc,
    # :tabo, and :tabn with a tab page number, which Vim's get_tabpage_arg
    # reads: 0 is E16 and a word or a number past the last tab page E475,
    # :tabc and :tabo with one tab page answering before reading it; :tabp
    # and :tabN with a positive count (E475 for another); :tabfir and :tabl
    # with none (E488).
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
        args = command.args
        case @variant
        when :open then @open_tab.call(state, args)
        when :previous then back(state, args)
        when :first, :last
          return Outcome.failure("E488: Trailing characters: #{args}") unless args.empty?
          @switch_tab.call(state, TabRequest.new(target: @variant, count: 0))
        else numbered(state, args)
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

      private

      # :tabp and :tabN, one tab page back, or count back with a positive
      # count.
      #: (Domain::EditorState, String) -> Outcome
      def back(state, args)
        return @switch_tab.call(state, TabRequest.new(target: :previous, count: 0)) if args.empty?
        return invalid(args) unless digits?(args) && args.bytesize <= 9 && args.to_i > 0
        @switch_tab.call(state, TabRequest.new(target: :previous, count: args.to_i))
      end

      # :tabn, :tabc, and :tabo on tab page number args, or without one on
      # the next and the current tab page.
      #: (Domain::EditorState, String) -> Outcome
      def numbered(state, args)
        count = state.tabs.tab_count
        number = 0
        unless args.empty? || (@variant != :next && count <= 1)
          return invalid(args) unless digits?(args) && args.bytesize <= 9
          number = args.to_i
          return Outcome.failure(Domain::Messages::E16) if number == 0
          return invalid(args) if number > count
        end
        case @variant
        when :close then @close_tab.call(state, number)
        when :only then @close_other_tabs.call(state, number)
        else @switch_tab.call(state, TabRequest.new(target: :next, count: number))
        end
      end

      #: (String) -> Outcome
      def invalid(args)
        Outcome.failure(Domain::Messages.invalid_argument(args))
      end

      # Whether the text is a run of ASCII digits.
      #: (String) -> bool
      def digits?(text)
        return false if text.empty?
        i = 0
        while i < text.bytesize
          code = text.getbyte(i).to_i
          return false if code < 48 || code > 57
          i += 1
        end
        true
      end
    end
  end
end
