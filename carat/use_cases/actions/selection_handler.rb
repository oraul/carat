require_relative "../../domain/mode"
require_relative "../visual/delete_selection"
require_relative "../visual/yank_selection"
require_relative "../visual/change_selection"
require_relative "../visual/join_selection"
require_relative "../visual/recase_selection"
require_relative "../visual/insert_at_selection"
require_relative "../visual/put_over_selection"
require_relative "../visual/swap_visual_ends"
require_relative "action_handler"
require_relative "action_table"

module Carat
  module UseCases
    # The visual.* keys that act on the selection, each through the
    # selection use case of its operation: J and gJ, p and P, r ~ u U, X
    # and D, S R and C, Y, I and A, and o and O through SwapVisualEnds.
    # Outside a visual mode they are not implemented, as before.
    # visual.replace reads one more key, the replacement character.
    class SelectionHandler < ActionHandler
      # @rbs @delete_selection: DeleteSelection
      # @rbs @yank_selection: YankSelection
      # @rbs @change_selection: ChangeSelection
      # @rbs @join_selection: JoinSelection
      # @rbs @recase_selection: RecaseSelection
      # @rbs @insert_at_selection: InsertAtSelection
      # @rbs @put_over_selection: PutOverSelection
      # @rbs @swap_visual_ends: SwapVisualEnds
      # @rbs @variant: Symbol

      #: (delete_selection: DeleteSelection, yank_selection: YankSelection, change_selection: ChangeSelection, join_selection: JoinSelection, recase_selection: RecaseSelection, insert_at_selection: InsertAtSelection, put_over_selection: PutOverSelection, swap_visual_ends: SwapVisualEnds, variant: Symbol, kind: Symbol) -> void
      def initialize(delete_selection:, yank_selection:, change_selection:, join_selection:, recase_selection:, insert_at_selection:, put_over_selection:, swap_visual_ends:, variant:, kind:)
        super(kind: kind, repeat: true)
        @delete_selection = delete_selection
        @yank_selection = yank_selection
        @change_selection = change_selection
        @join_selection = join_selection
        @recase_selection = recase_selection
        @insert_at_selection = insert_at_selection
        @put_over_selection = put_over_selection
        @swap_visual_ends = swap_visual_ends
        @variant = variant
      end

      # @rbs state: Domain::EditorState
      # @rbs command: Domain::Command
      def call(state, command)
        return Outcome.success("Not implemented: #{command.action}") unless Domain::Mode.visual?(state.mode)
        case @variant
        when :join then @join_selection.call(state, true)
        when :join_raw then @join_selection.call(state, false)
        when :put then @put_over_selection.call(state, command, false)
        when :put_keep then @put_over_selection.call(state, command, true)
        when :replace then @recase_selection.call(state, command, :replace)
        when :toggle_case then @recase_selection.call(state, command, :toggle)
        when :lowercase then @recase_selection.call(state, command, :lower)
        when :uppercase then @recase_selection.call(state, command, :upper)
        when :delete_lines then @delete_selection.call(state, command, :lines)
        when :delete_to_end then @delete_selection.call(state, command, :to_end)
        when :change_lines then @change_selection.call(state, command, :lines)
        when :change_to_end then @change_selection.call(state, command, :to_end)
        when :yank_lines then @yank_selection.call(state, command, true)
        when :insert then @insert_at_selection.call(state, false)
        when :append then @insert_at_selection.call(state, true)
        when :swap_ends then @swap_visual_ends.call(state, false)
        else @swap_visual_ends.call(state, true)
        end
      end

      #: (ActionTable, delete_selection: DeleteSelection, yank_selection: YankSelection, change_selection: ChangeSelection, join_selection: JoinSelection, recase_selection: RecaseSelection, insert_at_selection: InsertAtSelection, put_over_selection: PutOverSelection, swap_visual_ends: SwapVisualEnds) -> void
      def self.register(table, delete_selection:, yank_selection:, change_selection:, join_selection:, recase_selection:, insert_at_selection:, put_over_selection:, swap_visual_ends:)
        names = ["visual.join", "visual.join_raw", "visual.put", "visual.put_keep", "visual.replace", "visual.toggle_case", "visual.lowercase", "visual.uppercase", "visual.delete_lines", "visual.delete_to_end", "visual.change_lines", "visual.change_to_end", "visual.yank_lines", "visual.insert", "visual.append", "visual.swap_ends", "visual.swap_corner"]
        variants = [:join, :join_raw, :put, :put_keep, :replace, :toggle_case, :lowercase, :uppercase, :delete_lines, :delete_to_end, :change_lines, :change_to_end, :yank_lines, :insert, :append, :swap_ends, :swap_corner]
        i = 0
        while i < names.length
          kind = variants[i] == :replace ? :char : :action
          table.register(names[i], SelectionHandler.new(delete_selection: delete_selection, yank_selection: yank_selection, change_selection: change_selection, join_selection: join_selection, recase_selection: recase_selection, insert_at_selection: insert_at_selection, put_over_selection: put_over_selection, swap_visual_ends: swap_visual_ends, variant: variants[i], kind: kind))
          i += 1
        end
      end
    end
  end
end
