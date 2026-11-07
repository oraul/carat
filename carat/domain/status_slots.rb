module Carat
  module Domain
    # What git and the language services report on the status bar, empty
    # until they fill it: the current branch ("" for none), the current
    # buffer's diagnostics counts by severity, and the language server's
    # name ("" for none) with its state, :none, :starting, :ready,
    # :indexing, :stopped, or :crashed, and the label the bar draws, built
    # once by set_lsp so a render allocates nothing for it. The status bar
    # draws an empty slot in no cells. A Struct record: mutable, with a
    # reader and a writer per member.
    class StatusSlots < Struct.new(:branch, :errors, :warnings, :infos, :hints, :lsp_name, :lsp_state, :lsp_label, keyword_init: true)
      CRASH_HINT = "crashed :LspRestart"

      # @rbs @branch: String
      # @rbs @errors: Integer
      # @rbs @warnings: Integer
      # @rbs @infos: Integer
      # @rbs @hints: Integer
      # @rbs @lsp_name: String
      # @rbs @lsp_state: Symbol
      # @rbs @lsp_label: String

      # Every slot empty.
      #: () -> void
      def initialize
        super(branch: "", errors: 0, warnings: 0, infos: 0, hints: 0, lsp_name: "", lsp_state: :none, lsp_label: "")
      end

      # Shows a server's name in a state, with the percent when indexing;
      # an empty name empties the slot. Answers whether the slot changed.
      #: (String, Symbol, Integer) -> bool
      def set_lsp(name, state, percent)
        label = StatusSlots.label(name, state, percent)
        return false if name == lsp_name && state == lsp_state && label == lsp_label
        self.lsp_name = name
        self.lsp_state = name.empty? ? :none : state
        self.lsp_label = label
        true
      end

      # The text of the lsp slot: the name, then the state's words.
      #: (String, Symbol, Integer) -> String
      def self.label(name, state, percent)
        return "" if name.empty?
        return "#{name} starting" if state == :starting
        return "#{name} indexing #{percent}%" if state == :indexing
        return "#{name} stopped" if state == :stopped
        return "#{name} #{CRASH_HINT}" if state == :crashed
        name
      end

      # Whether any diagnostics count is above zero.
      #: () -> bool
      def diagnostics?
        errors > 0 || warnings > 0 || infos > 0 || hints > 0
      end

      # Whether a language server is named, so the lsp slot shows.
      #: () -> bool
      def lsp?
        !lsp_name.empty?
      end
    end
  end
end
