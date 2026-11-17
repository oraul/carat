require_relative "../../domain/editor_state"
require_relative "../../domain/search_prompt"
require_relative "../../domain/last_search"
require_relative "../../domain/last_substitute"
require_relative "../../domain/delimited_pattern"
require_relative "../../domain/vim_pattern"
require_relative "../../domain/search"
require_relative "../../domain/search_budget"
require_relative "../outcome"

module Carat
  module UseCases
    # incsearch: after each change of the search prompt's text the cursor
    # goes back to where the prompt opened and, when the option is on and
    # the pattern compiles and matches, moves to the first match in the
    # prompt's direction, which the last search keeps as the preview the
    # screen highlights. Nothing happens outside a search prompt; a
    # pattern that does not compile shows no error until Enter.
    class PreviewSearch
      attr_reader :search_prompt #: Domain::SearchPrompt
      attr_reader :last_search #: Domain::LastSearch
      attr_reader :last_substitute #: Domain::LastSubstitute

      # @rbs @budget: Domain::SearchBudget

      #: (search_prompt: Domain::SearchPrompt, last_search: Domain::LastSearch, last_substitute: Domain::LastSubstitute) -> void
      def initialize(search_prompt:, last_search:, last_substitute:)
        @search_prompt = search_prompt
        @last_search = last_search
        @last_substitute = last_substitute
        @budget = Domain::SearchBudget.new(left: Domain::SearchBudget::SEARCH)
      end

      #: (Domain::EditorState) -> Outcome
      def call(state)
        prompt = @search_prompt
        return Outcome.none unless prompt.active
        prompt.restore(state.window)
        options = state.options
        source = Domain::DelimitedPattern.typed(state.cmdline, prompt.forward).pattern
        unless options.incsearch && !source.empty?
          @last_search.end_preview
          return Outcome.none
        end
        memory = @last_substitute
        compiled = Domain::VimPattern.compile_search(source, options.ignorecase, options.smartcase, memory.previous, memory.previous_kept)
        unless compiled.ok?
          @last_search.end_preview
          return Outcome.none
        end
        budget = @budget
        budget.reset(Domain::SearchBudget::SEARCH)
        hit = Domain::Search.find(state.buffer, compiled, prompt.origin_row, prompt.origin_col, prompt.forward, 1, budget)
        unless hit.found?
          @last_search.preview_at(compiled, -1, 0, 0)
          return Outcome.none
        end
        cursor = state.cursor
        cursor.row = hit.row
        cursor.col = state.clamp_col(hit.row, hit.col)
        @last_search.preview_at(compiled, hit.row, hit.col, hit.end_col)
        Outcome.none
      end
    end
  end
end
