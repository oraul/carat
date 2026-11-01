require_relative "../../domain/mode"
require_relative "../visual/extend_visual"
require_relative "../visual/operate_on_selection"
require_relative "action_handler"
require_relative "action_table"

module Carat
  module UseCases
    # The visual.* keys that act on the selection: o and O through
    # ExtendVisual, the rest through OperateOnSelection. Outside a visual
    # mode they are not implemented, as before. visual.replace reads one
    # more key, the replacement character.
    class SelectionHandler < ActionHandler
      # @rbs @selection: OperateOnSelection
      # @rbs @extend_visual: ExtendVisual
      # @rbs @variant: Symbol

      #: (selection: OperateOnSelection, extend_visual: ExtendVisual, variant: Symbol, kind: Symbol) -> void
      def initialize(selection:, extend_visual:, variant:, kind:)
        super(kind: kind, repeat: true)
        @selection = selection
        @extend_visual = extend_visual
        @variant = variant
      end

      # @rbs state: Domain::EditorState
      # @rbs command: Domain::Command
      def call(state, command)
        return Outcome.success("Not implemented: #{command.action}") unless Domain::Mode.visual?(state.mode)
        selection = @selection
        case @variant
        when :join then selection.join(state, command, true)
        when :join_raw then selection.join(state, command, false)
        when :put then selection.put(state, command, false)
        when :put_keep then selection.put(state, command, true)
        when :replace then selection.recase(state, command, :replace)
        when :toggle_case then selection.recase(state, command, :toggle)
        when :lowercase then selection.recase(state, command, :lower)
        when :uppercase then selection.recase(state, command, :upper)
        when :delete_lines then selection.delete_lines(state, command, false)
        when :delete_to_end then selection.delete_lines(state, command, true)
        when :change_lines then selection.change_lines(state, command, false)
        when :change_to_end then selection.change_lines(state, command, true)
        when :yank_lines then selection.yank_lines(state, command)
        when :insert then selection.insert(state, command, false)
        when :append then selection.insert(state, command, true)
        when :swap_ends then @extend_visual.swap_ends(state)
        else @extend_visual.swap_corner(state)
        end
      end

      #: (ActionTable, selection: OperateOnSelection, extend_visual: ExtendVisual) -> void
      def self.register(table, selection:, extend_visual:)
        add(table, "visual.join", selection, extend_visual, :join)
        add(table, "visual.join_raw", selection, extend_visual, :join_raw)
        add(table, "visual.put", selection, extend_visual, :put)
        add(table, "visual.put_keep", selection, extend_visual, :put_keep)
        table.register("visual.replace", SelectionHandler.new(selection: selection, extend_visual: extend_visual, variant: :replace, kind: :char))
        add(table, "visual.toggle_case", selection, extend_visual, :toggle_case)
        add(table, "visual.lowercase", selection, extend_visual, :lowercase)
        add(table, "visual.uppercase", selection, extend_visual, :uppercase)
        add(table, "visual.delete_lines", selection, extend_visual, :delete_lines)
        add(table, "visual.delete_to_end", selection, extend_visual, :delete_to_end)
        add(table, "visual.change_lines", selection, extend_visual, :change_lines)
        add(table, "visual.change_to_end", selection, extend_visual, :change_to_end)
        add(table, "visual.yank_lines", selection, extend_visual, :yank_lines)
        add(table, "visual.insert", selection, extend_visual, :insert)
        add(table, "visual.append", selection, extend_visual, :append)
        add(table, "visual.swap_ends", selection, extend_visual, :swap_ends)
        add(table, "visual.swap_corner", selection, extend_visual, :swap_corner)
      end

      #: (ActionTable, String, OperateOnSelection, ExtendVisual, Symbol) -> void
      def self.add(table, name, selection, extend_visual, variant)
        table.register(name, SelectionHandler.new(selection: selection, extend_visual: extend_visual, variant: variant, kind: :action))
      end
    end
  end
end
