module Carat
  module Domain
    # What git and the language services report on the status bar, empty
    # until they fill it: the current branch ("" for none), the current
    # buffer's diagnostics counts by severity, and the language server's
    # name ("" for none) with its state, :none, :starting, :ready, or
    # :error. The status bar draws an empty slot in no cells. A Struct
    # record: mutable, with a reader and a writer per member.
    class StatusSlots < Struct.new(:branch, :errors, :warnings, :infos, :hints, :lsp_name, :lsp_state, keyword_init: true)
      # @rbs @branch: String
      # @rbs @errors: Integer
      # @rbs @warnings: Integer
      # @rbs @infos: Integer
      # @rbs @hints: Integer
      # @rbs @lsp_name: String
      # @rbs @lsp_state: Symbol

      # Every slot empty.
      #: () -> void
      def initialize
        super(branch: "", errors: 0, warnings: 0, infos: 0, hints: 0, lsp_name: "", lsp_state: :none)
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
