require_relative "../../domain/editor_state"
require_relative "../../domain/registers"
require_relative "../../domain/history"
require_relative "../../domain/last_search"
require_relative "../../domain/last_substitute"
require_relative "../../domain/substitute_args"
require_relative "../../domain/vim_pattern"
require_relative "../../domain/search"
require_relative "../../domain/search_budget"
require_relative "../../domain/substitution"
require_relative "../../domain/text_lines"
require_relative "../outcome"

module Carat
  module UseCases
    # :s, :&, "&", and "g&" on the rows first to last: the pattern and the
    # string typed, or the last substitute's, with the flags Vim's rules
    # give (LastSubstitute keeps what the next one reuses). The pattern is
    # compiled as a search pattern with capturing groups and becomes the
    # last search pattern, the "/" register, and, when typed, a search
    # history entry. Every line is substituted under one budget before
    # anything changes; the changed rows are then replaced in one splice,
    # which is one undo state inside the dispatcher's transaction, and the
    # cursor goes to the first non-blank of the last line changed. The
    # messages are Vim's: E33, E35, E486 (not with "e"), E939, E363 when
    # the budget ran out, the count above two substitutions, the count of
    # "n", or the last line with "p" or "#".
    class SubstituteLines
      attr_reader :last_substitute #: Domain::LastSubstitute
      attr_reader :last_search #: Domain::LastSearch
      attr_reader :registers #: Domain::Registers
      attr_reader :search_history #: Domain::History

      # @rbs @budget: Domain::SearchBudget

      NO_SUBSTITUTE = "E33: No previous substitute regular expression"
      # Vim's 'report': more substitutions than this are reported.
      REPORT = 2
      private_constant :NO_SUBSTITUTE, :REPORT

      #: (last_substitute: Domain::LastSubstitute, last_search: Domain::LastSearch, registers: Domain::Registers, search_history: Domain::History) -> void
      def initialize(last_substitute:, last_search:, registers:, search_history:)
        @last_substitute = last_substitute
        @last_search = last_search
        @registers = registers
        @search_history = search_history
        @budget = Domain::SearchBudget.new(left: Domain::SearchBudget::SEARCH)
      end

      #: (Domain::EditorState, Integer, Integer, Domain::SubstituteArgs) -> Outcome
      def call(state, first, last, args)
        return Outcome.failure(args.error) unless args.ok?
        memory = @last_substitute
        if args.fresh
          memory.keep_replacement(args.replacement)
        elsif !memory.replacement_kept
          return Outcome.failure(NO_SUBSTITUTE)
        end
        flags = args.flags
        return Outcome.success("Not implemented: :s flag c") if flags.include?("c")
        return Outcome.success("Not implemented: :s flag l") if flags.include?("l")
        memory.apply_flags(flags)
        if args.count == 0
          return memory.report ? Outcome.failure("E939: Positive count required") : Outcome.none
        end
        if args.count > 0
          first = last
          last += args.count - 1
          last = state.buffer.line_count - 1 if last > state.buffer.line_count - 1
        end
        use_search = args.fresh || flags.include?("r")
        source = pattern_source(args, use_search)
        return Outcome.failure(use_search ? Domain::Search::NO_PREVIOUS : NO_SUBSTITUTE) if source.empty?
        compiled = compile(state, source)
        return Outcome.failure(compiled.error) unless compiled.ok?
        remember(compiled, args)
        return Outcome.failure(Domain::Replacement::TOO_LONG) if Domain::Replacement.too_long?(memory.replacement, memory.previous)
        text = Domain::Replacement.tilde(memory.replacement, memory.previous, memory.previous_kept)
        memory.keep_previous(text)
        unless memory.count_only
          refused = Domain::Replacement.check(text)
          return Outcome.success(refused) unless refused.empty?
        end
        run(state, first, last, compiled, text)
      end

      private

      # The pattern this substitute uses: the one typed, else the last
      # search pattern (for a typed empty one or the "r" flag) or the last
      # substitute's; "" when there is none.
      #: (Domain::SubstituteArgs, bool) -> String
      def pattern_source(args, use_search)
        return args.pattern if args.fresh && !args.pattern.empty?
        use_search ? @last_search.pattern : @last_substitute.pattern
      end

      #: (Domain::EditorState, String) -> Domain::SearchPattern
      def compile(state, source)
        memory = @last_substitute
        ignorecase = state.options.ignorecase
        smartcase = state.options.smartcase
        if memory.case_mode == 1
          ignorecase = true
          smartcase = false
        elsif memory.case_mode == 2
          ignorecase = false
        end
        Domain::VimPattern.compile_substitute(source, ignorecase, smartcase, memory.previous, memory.previous_kept)
      end

      #: (Domain::SearchPattern, Domain::SubstituteArgs) -> void
      def remember(compiled, args)
        source = compiled.source
        @last_substitute.pattern = source
        @last_search.remember(compiled, @last_search.forward)
        @registers.search = source
        @search_history.add(source) if args.fresh && !args.pattern.empty?
      end

      # Substitutes every row, then applies the changed span.
      #: (Domain::EditorState, Integer, Integer, Domain::SearchPattern, String) -> Outcome
      def run(state, first, last, compiled, text)
        memory = @last_substitute
        buffer = state.buffer
        budget = @budget
        budget.reset(Domain::SearchBudget::SEARCH)
        rows = Array.new(0, 0)
        texts = Array.new(0, "")
        total = 0
        row = first
        while row <= last
          result = Domain::Substitution.line(compiled, buffer.line(row), text, memory.all, memory.count_only, budget)
          return Outcome.failure(Domain::Search::STOPPED) if budget.stopped
          if result.changed?
            total += result.count
            rows << row
            texts << result.text
          end
          row += 1
        end
        if total == 0
          return memory.report ? Outcome.failure("E486: Pattern not found: #{compiled.source}") : Outcome.none
        end
        return Outcome.success("#{plural(total, "match", "matches")} on #{plural(rows.length, "line", "lines")}") if memory.count_only
        landed = apply(buffer, rows, texts)
        state.cursor.move_to(landed, buffer.first_nonblank(landed))
        return Outcome.success(printed(buffer, landed, memory.print == 2)) if memory.print > 0
        return Outcome.none if total <= REPORT
        Outcome.success("#{plural(total, "substitution", "substitutions")} on #{plural(rows.length, "line", "lines")}")
      end

      # Replaces the span from the first to the last changed row in one
      # splice, a changed row by its lines and any other kept as it is, and
      # returns the row of the last line the last change made.
      #: (Domain::Buffer, Array[Integer], Array[String]) -> Integer
      def apply(buffer, rows, texts)
        from = rows[0].to_i
        to = rows[rows.length - 1].to_i
        span = Array.new(0, "")
        landed = from
        k = 0
        row = from
        while row <= to
          if k < rows.length && rows[k].to_i == row
            piece = texts[k].to_s
            if piece.include?(Domain::Replacement::BREAK)
              parts = Domain::TextLines.split(piece, false)
              i = 0
              while i < parts.length
                span << parts[i].to_s
                i += 1
              end
            else
              span << piece
            end
            landed = from + span.length - 1
            k += 1
          else
            span << buffer.line(row)
          end
          row += 1
        end
        buffer.set_lines(from, to + 1, span)
        landed
      end

      # The line as "p" shows it, or with its number as "#" does.
      #: (Domain::Buffer, Integer, bool) -> String
      def printed(buffer, row, numbered)
        line = buffer.line(row)
        return line unless numbered
        "#{(row + 1).to_s.rjust(3)} #{line}"
      end

      #: (Integer, String, String) -> String
      def plural(count, one, many)
        "#{count} #{count == 1 ? one : many}"
      end
    end
  end
end
