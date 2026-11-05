require_relative "../../domain/editor_state"
require_relative "../../domain/registers"
require_relative "../../domain/history"
require_relative "../../domain/last_search"
require_relative "../../domain/last_substitute"
require_relative "../../domain/global_args"
require_relative "../../domain/vim_pattern"
require_relative "../../domain/search"
require_relative "../../domain/search_budget"
require_relative "../ex/command_runner"
require_relative "../outcome"

module Carat
  module UseCases
    # :g, :g!, and :v on the rows first to last, as Vim's :global works:
    # every row the pattern matches (or, inverted, does not) is marked in
    # the buffer's GlobalMarks under one search budget, then the command
    # runs through the CommandRunner with the cursor at the start of each
    # marked row in turn, the first first. The marks move with every edit,
    # so a marked row a command deletes is not visited and rows it inserts
    # are not marked. Without a command the marked rows are listed. The
    # pattern is compiled as a search pattern and becomes the last search
    # and substitute pattern, the "/" register, and, when typed, a search
    # history entry. The edits are one undo state; the first failing
    # command stops the global with its message, which is otherwise the
    # last a command gave, and so does a command that leaves the buffer.
    # A global run by a global's command acts on the cursor row only, E147
    # with a range other than every row.
    class GlobalCommand
      attr_reader :runner #: CommandRunner
      attr_reader :last_search #: Domain::LastSearch
      attr_reader :last_substitute #: Domain::LastSubstitute
      attr_reader :registers #: Domain::Registers
      attr_reader :search_history #: Domain::History

      # @rbs @budget: Domain::SearchBudget
      # @rbs @busy: bool

      RECURSIVE = "E147: Cannot do :global recursive with a range"
      private_constant :RECURSIVE

      #: (runner: CommandRunner, last_search: Domain::LastSearch, last_substitute: Domain::LastSubstitute, registers: Domain::Registers, search_history: Domain::History) -> void
      def initialize(runner:, last_search:, last_substitute:, registers:, search_history:)
        @runner = runner
        @last_search = last_search
        @last_substitute = last_substitute
        @registers = registers
        @search_history = search_history
        @budget = Domain::SearchBudget.new(left: Domain::SearchBudget::SEARCH)
        @busy = false
      end

      # text is the argument after the name; invert is true for :g! and
      # :v.
      #: (Domain::EditorState, Integer, Integer, String, bool) -> Outcome
      def call(state, first, last, text, invert)
        args = Domain::GlobalArgs.parse(text)
        return Outcome.failure(args.error) unless args.ok?
        buffer = state.buffer
        return Outcome.failure(RECURSIVE) if @busy && (first != 0 || last != buffer.line_count - 1)
        typed = !args.pattern.empty?
        source = typed ? args.pattern : @last_search.pattern
        return Outcome.failure(Domain::Search::NO_PREVIOUS) if source.empty?
        compiled = Domain::VimPattern.compile(source, state.options.ignorecase, state.options.smartcase)
        return Outcome.failure(compiled.error) unless compiled.ok?
        remember(compiled, typed)
        @budget.reset(Domain::SearchBudget::SEARCH)
        return nested(state, compiled, args.command, invert) if @busy
        rows = marked_rows(buffer, first, last, compiled, invert)
        return Outcome.failure(Domain::Search::STOPPED) if @budget.stopped
        if rows.empty?
          return Outcome.success(invert ? "Pattern found in every line: #{source}" : "Pattern not found: #{source}")
        end
        return listed(state, rows) if args.command.empty?
        run(state, buffer, rows, args.command)
      end

      private

      #: (Domain::SearchPattern, bool) -> void
      def remember(compiled, typed)
        source = compiled.source
        @last_search.remember(compiled, @last_search.forward)
        @last_substitute.pattern = source
        @registers.search = source
        @search_history.add(source) if typed
      end

      # The rows from first to last the pattern matches, or does not when
      # invert; stops early when the budget runs out.
      #: (Domain::Buffer, Integer, Integer, Domain::SearchPattern, bool) -> Array[Integer]
      def marked_rows(buffer, first, last, compiled, invert)
        rows = Array.new(0, 0)
        row = first
        while row <= last
          found = matches?(compiled, buffer.line(row))
          return rows if @budget.stopped
          rows << row if found != invert
          row += 1
        end
        rows
      end

      #: (Domain::SearchPattern, String) -> bool
      def matches?(compiled, line)
        text = Domain::Search.searchable(line)
        !Domain::Search.match_at(compiled, text, text.length, 0, @budget).nil?
      end

      # A global inside a global: the command on the cursor row when the
      # pattern marks it, nothing otherwise.
      #: (Domain::EditorState, Domain::SearchPattern, String, bool) -> Outcome
      def nested(state, compiled, command, invert)
        row = state.cursor.row
        found = matches?(compiled, state.buffer.line(row))
        return Outcome.failure(Domain::Search::STOPPED) if @budget.stopped
        return Outcome.none if found == invert
        return listed(state, [row]) if command.empty?
        @runner.call(state, command)
      end

      # The marked rows as a listing, one per line, the cursor on the first
      # non-blank of the last.
      #: (Domain::EditorState, Array[Integer]) -> Outcome
      def listed(state, rows)
        buffer = state.buffer
        out = +""
        i = 0
        while i < rows.length
          out << "\n" if i > 0
          out << buffer.line(rows[i].to_i)
          i += 1
        end
        row = rows[rows.length - 1].to_i
        state.cursor.move_to(row, buffer.first_nonblank(row))
        Outcome.success(out)
      end

      # Runs command on every marked row inside one transaction and leaves
      # the cursor inside the buffer.
      #: (Domain::EditorState, Domain::Buffer, Array[Integer], String) -> Outcome
      def run(state, buffer, rows, command)
        before = state.cursor.position
        opened = buffer.begin_transaction(before)
        said = visit(state, buffer, rows, command)
        same = state.buffer.equal?(buffer)
        if same
          cursor = state.cursor
          row = cursor.row
          row = buffer.line_count - 1 if row > buffer.line_count - 1
          cursor.move_to(row, state.clamp_col(row, cursor.col))
        end
        buffer.commit_transaction(same ? state.cursor.position : before) if opened
        said
      end

      # The loop over the marked rows; the marks are dropped and the global
      # is no longer busy however it ends.
      #: (Domain::EditorState, Domain::Buffer, Array[Integer], String) -> Outcome
      def visit(state, buffer, rows, command)
        marks = buffer.global_marks
        marks.mark(rows, buffer.line_count)
        @busy = true
        begin
          said = Outcome.none
          row = marks.take
          while row >= 0
            state.cursor.move_to(row, 0)
            outcome = @runner.call(state, command)
            return outcome unless outcome.ok
            said = outcome unless outcome.message.empty?
            break unless state.buffer.equal?(buffer)
            row = marks.take
          end
          said
        ensure
          @busy = false
          marks.clear
        end
      end
    end
  end
end
