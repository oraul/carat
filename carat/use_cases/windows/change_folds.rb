require_relative "../../domain/editor_state"
require_relative "../../domain/messages"
require_relative "../outcome"

module Carat
  module UseCases
    # The fold keys of the current window but zf with a motion, which
    # Operate carries out: :create folds the visual selection's lines and
    # leaves visual mode (zf), :open opens the closed fold under the
    # cursor (zo), :close closes the innermost open one (zc), :toggle
    # does either (za), :delete deletes the fold under the cursor (zd),
    # :eliminate every fold (zE), :open_all opens every fold (zR), and
    # :close_all closes every fold (zM). With no fold under the cursor zo,
    # zc, za, and zd give E490; the cursor goes to the first line of the
    # closed fold it is left in, as Neovim's cursor adjustment puts it.
    class ChangeFolds
      #: (Domain::EditorState, Symbol) -> Outcome
      def call(state, target)
        window = state.window
        if target == :create
          selection = state.end_visual
          window.add_fold(selection.top, selection.bottom)
          return place(state, selection.top)
        end
        if target == :eliminate
          window.drop_folds
          return Outcome.none
        end
        folds = window.folds
        row = state.cursor.row
        if target == :open_all
          folds.open_all
          return Outcome.none
        end
        if target == :close_all
          folds.close_all
          return place(state, row)
        end
        found = case target
                when :open then folds.open_at(row)
                when :close then folds.close_at(row)
                when :toggle then folds.toggle_at(row)
                else window.delete_fold(row)
                end
        return Outcome.failure(Domain::Messages::E490) unless found
        place(state, row)
      end

      private

      # Moves the cursor to the first line of the closed fold at row, if
      # row is in one.
      #: (Domain::EditorState, Integer) -> Outcome
      def place(state, row)
        cursor = state.cursor
        first = state.window.folds.first_row(row)
        cursor.move_to(first, state.clamp_col(first, cursor.col)) if first != cursor.row
        Outcome.none
      end
    end
  end
end
