require_relative "../../domain/editor_state"
require_relative "../../domain/command"
require_relative "../../domain/registers"
require_relative "../../domain/history"
require_relative "../../domain/last_search"
require_relative "../../domain/vim_pattern"
require_relative "../../domain/search"
require_relative "../../domain/search_budget"
require_relative "../../domain/search_hit"
require_relative "../../domain/motions"
require_relative "../../domain/utf8"

module Carat
  module UseCases
    # Where a search command lands, from the cursor: "/" and "?" with the
    # pattern the prompt gave as the command's argument (the last pattern
    # when it is empty), "n" and "N" with the last pattern in its
    # direction or the other, and "*", "#", "g*", and "g#" with the
    # keyword under or after the cursor, which becomes the last pattern
    # and a history entry. A new pattern is remembered with its direction
    # in the last search and the "/" register even when it is not found;
    # one that does not compile is not. The hit carries the message to
    # show: the pattern with its prompt character, the wrap message, or
    # the error. Every search runs under one budget, so no pattern can
    # hold the editor.
    class FindMatch
      attr_reader :last_search #: Domain::LastSearch
      attr_reader :registers #: Domain::Registers
      attr_reader :search_history #: Domain::History

      # @rbs @budget: Domain::SearchBudget

      #: (last_search: Domain::LastSearch, registers: Domain::Registers, search_history: Domain::History) -> void
      def initialize(last_search:, registers:, search_history:)
        @last_search = last_search
        @registers = registers
        @search_history = search_history
        @budget = Domain::SearchBudget.new(left: Domain::SearchBudget::SEARCH)
      end

      #: (Domain::EditorState, Domain::Command) -> Domain::SearchHit
      def call(state, command)
        count = command.count
        case command.action
        when "search.forward" then typed(state, command.char, true, count)
        when "search.backward" then typed(state, command.char, false, count)
        when "search.next" then again(state, true, count)
        when "search.previous" then again(state, false, count)
        when "search.word_forward" then word(state, true, true, count)
        when "search.word_backward" then word(state, false, true, count)
        when "search.partial_word_forward" then word(state, true, false, count)
        when "search.partial_word_backward" then word(state, false, false, count)
        else refuse(state, "Not implemented: #{command.action}")
        end
      end

      private

      #: (Domain::EditorState, String) -> Domain::SearchHit
      def refuse(state, message)
        cursor = state.cursor
        Domain::SearchHit.refused(cursor.row, cursor.col, message)
      end

      # "/" or "?" with what was typed at the prompt.
      #: (Domain::EditorState, String, bool, Integer) -> Domain::SearchHit
      def typed(state, text, forward, count)
        stop = Domain::VimPattern.pattern_end(text, forward ? 47 : 63)
        source = text.byteslice(0, stop).to_s
        offset = text.byteslice(stop + 1, text.bytesize - stop).to_s
        return refuse(state, "Not implemented: search offset #{offset}") unless offset.empty?
        if source.empty?
          return refuse(state, Domain::Search::NO_PREVIOUS) unless @last_search.any?
          source = @last_search.pattern
        end
        options = state.options
        compiled = Domain::VimPattern.compile(source, options.ignorecase, options.smartcase)
        return refuse(state, compiled.error) unless compiled.ok?
        remember(compiled, forward)
        cursor = state.cursor
        run(state, compiled, forward, count, cursor.row, cursor.col)
      end

      # "n" (same) and "N" (reversed): the last pattern again.
      #: (Domain::EditorState, bool, Integer) -> Domain::SearchHit
      def again(state, same, count)
        last = @last_search
        return refuse(state, Domain::Search::NO_PREVIOUS) unless last.any?
        compiled = last.compiled
        return refuse(state, compiled.error) unless compiled.ok?
        last.show
        cursor = state.cursor
        run(state, compiled, same ? last.forward : !last.forward, count, cursor.row, cursor.col)
      end

      # "*", "#", "g*", and "g#": the keyword under or after the cursor,
      # as a whole word when whole is set, or the non-blank text there
      # when the line has no keyword after the cursor. smartcase does not
      # apply, as in Vim.
      #: (Domain::EditorState, bool, bool, Integer) -> Domain::SearchHit
      def word(state, forward, whole, count)
        cursor = state.cursor
        line = state.current_line
        codes = Domain::Utf8.codes(line)
        n = codes.length
        start = cursor.col
        start += 1 while start < n && !keyword?(codes[start])
        keyword = start < n
        unless keyword
          start = cursor.col
          start += 1 while start < n && blank?(codes[start])
          return refuse(state, Domain::Search::NO_STRING) if start >= n
        end
        if start == cursor.col
          start -= 1 while start > 0 && same_kind?(codes[start - 1], keyword)
        end
        stop = start
        stop += 1 while stop < n && same_kind?(codes[stop], keyword)
        text = Domain::VimPattern.escape(line[start, stop - start].to_s)
        text = "\\<#{text}\\>" if whole && keyword
        compiled = Domain::VimPattern.compile(text, state.options.ignorecase, false)
        return refuse(state, compiled.error) unless compiled.ok?
        remember(compiled, forward)
        @search_history.add(text)
        run(state, compiled, forward, count, cursor.row, start)
      end

      #: (Integer) -> bool
      def keyword?(code)
        Domain::Motions.code_class(code, false) == 2
      end

      #: (Integer) -> bool
      def blank?(code)
        code == 32 || code == 9
      end

      # Whether a code point continues the text being taken: a keyword
      # character for a keyword, a non-blank one that is not a keyword
      # character otherwise.
      #: (Integer, bool) -> bool
      def same_kind?(code, keyword)
        keyword ? keyword?(code) : !blank?(code) && !keyword?(code)
      end

      #: (Domain::SearchPattern, bool) -> void
      def remember(compiled, forward)
        @last_search.remember(compiled, forward)
        @registers.search = compiled.source
      end

      #: (Domain::EditorState, Domain::SearchPattern, bool, Integer, Integer, Integer) -> Domain::SearchHit
      def run(state, compiled, forward, count, row, col)
        budget = @budget
        budget.reset(Domain::SearchBudget::SEARCH)
        hit = Domain::Search.find(state.buffer, compiled, row, col, forward, count, budget)
        case hit.status
        when :found
          hit.message = hit.wrapped ? (forward ? Domain::Search::BOTTOM : Domain::Search::TOP) : "#{forward ? "/" : "?"}#{compiled.source}"
        when :stopped
          hit.message = Domain::Search::STOPPED
        else
          hit.message = "E486: Pattern not found: #{compiled.source}"
        end
        hit
      end
    end
  end
end
