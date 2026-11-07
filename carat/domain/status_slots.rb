require_relative "diagnostic"

module Carat
  module Domain
    # What git and the language services report on the status bar, empty
    # until they fill it: the current branch ("" for none), the current
    # buffer's diagnostics counts by severity, and the language server's
    # name ("" for none) with its state, :none, :starting, :ready,
    # :indexing, :stopped, :crashed, or :untrusted (configured but not
    # started, the directory not trusted), and the label the bar draws, built
    # once by set_lsp so a render allocates nothing for it. The status bar
    # draws an empty slot in no cells. A Struct record: mutable, with a
    # reader and a writer per member.
    class StatusSlots < Struct.new(:branch, :errors, :warnings, :infos, :hints, :lsp_name, :lsp_state, :lsp_label, keyword_init: true)
      CRASH_HINT = "crashed :LspRestart"
      UNTRUSTED_HINT = "untrusted :LspStart"

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
        return "#{name} #{UNTRUSTED_HINT}" if state == :untrusted
        name
      end

      # Counts a buffer's diagnostics by severity into the four counts;
      # answers whether a count changed.
      #: (Array[untyped]) -> bool
      def count_diagnostics(list)
        counts = [0, 0, 0, 0, 0]
        i = 0
        while i < list.length
          diagnostic = StatusSlots.diagnostic_in(list, i)
          if diagnostic.error?
            counts[1] += 1
          else
            counts[diagnostic.severity] += 1
          end
          i += 1
        end
        return false if counts[1] == errors && counts[2] == warnings && counts[3] == infos && counts[4] == hints
        self.errors = counts[1]
        self.warnings = counts[2]
        self.infos = counts[3]
        self.hints = counts[4]
        true
      end

      #: (Array[untyped], Integer) -> Diagnostic
      def self.diagnostic_in(list, i)
        list[i]
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
