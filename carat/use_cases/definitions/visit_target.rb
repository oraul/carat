require_relative "../../domain/editor_state"
require_relative "../../domain/buffer"
require_relative "../../domain/buffer_list"
require_relative "../../domain/definition_request"
require_relative "../../domain/filetype"
require_relative "../../domain/jump_list"
require_relative "../../domain/messages"
require_relative "../../domain/path_info"
require_relative "../../domain/path_policy"
require_relative "../../domain/window"
require_relative "../../ports/file_port"
require_relative "../outcome"
require_relative "../files/open_file"
require_relative "../files/probe_path"
require_relative "../files/resolve_inside"
require_relative "open_definition_float"

module Carat
  module UseCases
    # Goes to, or peeks at, one target of the definition answer, by its
    # index. A jump moves the cursor in the current buffer when the target
    # is its file; another file is refused with E37 while the current file
    # buffer is modified, opens through OpenFile when it lies inside the
    # working directory with every link resolved, and otherwise opens as a
    # read-only scratch view titled with its path, never written. The
    # position left joins the jump list once the target shows. A peek
    # shows at most PEEK_ROWS lines from the target line in a float at the
    # cursor, read from a listed buffer of the file or from the file. Every
    # read refuses what OpenFile refuses (PathInfo#refusal): a directory, a
    # file that is not regular, and a file over its limit.
    class VisitTarget
      PEEK_LIMIT = 8_388_608
      PEEK_ROWS = 12
      private_constant :PEEK_LIMIT, :PEEK_ROWS

      attr_reader :definition #: Domain::DefinitionRequest
      attr_reader :jumps #: Domain::JumpList
      attr_reader :buffers #: Domain::BufferList
      attr_reader :files #: Ports::FilePort
      attr_reader :probe_path #: ProbePath
      attr_reader :open_file #: OpenFile
      attr_reader :resolve_inside #: ResolveInside
      attr_reader :open_definition_float #: OpenDefinitionFloat

      #: (definition: Domain::DefinitionRequest, jumps: Domain::JumpList, buffers: Domain::BufferList, files: Ports::FilePort, probe_path: ProbePath, open_file: OpenFile, resolve_inside: ResolveInside, open_definition_float: OpenDefinitionFloat) -> void
      def initialize(definition:, jumps:, buffers:, files:, probe_path:, open_file:, resolve_inside:, open_definition_float:)
        @definition = definition
        @jumps = jumps
        @buffers = buffers
        @files = files
        @probe_path = probe_path
        @open_file = open_file
        @resolve_inside = resolve_inside
        @open_definition_float = open_definition_float
      end

      #: (Domain::EditorState, Integer) -> Outcome
      def call(state, index)
        definition = @definition
        return Outcome.none if index < 0 || index >= definition.target_count
        path = definition.target_paths[index].to_s
        line = definition.target_rows[index].to_i
        return peek(state, path, line) if definition.peek
        jump(state, path, line, definition.target_characters[index].to_i)
      end

      private

      #: (Domain::EditorState, String, Integer, Integer) -> Outcome
      def jump(state, path, line, character)
        window = state.window
        current = window.buffer
        from_id = current.id
        from_row = window.cursor.row
        from_col = window.cursor.col
        outcome = Outcome.none
        unless absolute(current.path_text) == path || (current.scratch? && current.owner == Domain::DefinitionRequest::OWNER && current.title == path)
          return Outcome.failure(Domain::Messages::E37) if current.modified? && !current.scratch?
          outcome = inside?(path) ? @open_file.call(state, open_path(path)) : view(state, path)
          return outcome unless outcome.ok
        end
        @jumps.push(from_id, from_row, from_col)
        place(state.window, line, character)
        outcome
      end

      # Shows the read-only view of a file outside the project, reused
      # while it is listed.
      #: (Domain::EditorState, String) -> Outcome
      def view(state, path)
        listed = @buffers.scratch_for(Domain::DefinitionRequest::OWNER, path)
        unless listed.nil?
          @buffers.load(listed)
          return Outcome.success("\"#{path}\" [readonly]")
        end
        problem = @probe_path.call(path).refusal(path, Domain::PathInfo::BUFFER_LIMIT)
        return Outcome.failure(problem) unless problem.empty?
        text = read(path, Domain::PathInfo::BUFFER_LIMIT)
        return Outcome.failure("E484: Can't open file #{path}") if text.nil?
        buffer = Domain::Buffer.from_text(text, nil)
        buffer.owner = Domain::DefinitionRequest::OWNER
        buffer.title = path
        buffer.assign_filetype(Domain::Filetype.detect(path, buffer.line(0)))
        @buffers.load(buffer)
        Outcome.success("\"#{path}\" [readonly] #{buffer.line_count}L, #{text.bytesize}B")
      end

      #: (Domain::EditorState, String, Integer) -> Outcome
      def peek(state, path, line)
        source = listed_for(path)
        if source.nil?
          problem = @probe_path.call(path).refusal(path, PEEK_LIMIT)
          return Outcome.failure(problem) unless problem.empty?
          text = read(path, PEEK_LIMIT)
          return Outcome.failure("E484: Can't open file #{path}") if text.nil?
          source = Domain::Buffer.from_text(text, nil)
        end
        first = clamp(line, source.line_count)
        rows = [""]
        rows.clear
        row = first
        while row < source.line_count && rows.length < PEEK_ROWS
          rows << source.line(row)
          row += 1
        end
        buffer = Domain::Buffer.new(lines: rows, path: nil, line_ending: "\n")
        buffer.owner = Domain::DefinitionRequest::OWNER
        buffer.assign_filetype(Domain::Filetype.detect(path, source.line(0)))
        title = "#{Domain::PathPolicy.shown(@files.cwd, path)}:#{first + 1}"
        @definition.float_id = @open_definition_float.call(state, buffer, title, false)
        Outcome.none
      end

      # A listed buffer showing the file, its read-only view included, or
      # nil.
      #: (String) -> Domain::Buffer?
      def listed_for(path)
        i = 0
        while i < @buffers.count
          candidate = @buffers.buffer_at(i)
          return candidate if !candidate.scratch? && absolute(candidate.path_text) == path
          i += 1
        end
        @buffers.scratch_for(Domain::DefinitionRequest::OWNER, path)
      end

      # The path OpenFile is given: a listed buffer's own, so it is shown
      # and not read again, else the target relative to the working
      # directory, as :e would name it.
      #: (String) -> String
      def open_path(path)
        listed = listed_for(path)
        return listed.path_text if !listed.nil? && !listed.scratch?
        Domain::PathPolicy.shown(@files.cwd, path)
      end

      # Whether the target lies below the working directory, also once
      # every link of it is resolved.
      #: (String) -> bool
      def inside?(path)
        cwd = @files.cwd
        Domain::PathPolicy.inside?(cwd, path) && @resolve_inside.call(cwd, path, path).ok
      end

      #: (String) -> String
      def absolute(path)
        return "" if path.empty?
        path.start_with?("/") ? path : "#{@files.cwd}/#{path}"
      end

      # The file's text, nil when the read fails.
      #: (String, Integer) -> String?
      def read(path, limit)
        @files.read(path, limit)
      rescue StandardError
        nil
      end

      #: (Domain::Window, Integer, Integer) -> void
      def place(window, line, character)
        buffer = window.buffer
        row = clamp(line, buffer.line_count)
        window.cursor.move_to(row, column_of(buffer.line(row), character))
      end

      #: (Integer, Integer) -> Integer
      def clamp(line, count)
        return 0 if line < 0 || count < 1
        line >= count ? count - 1 : line
      end

      # The byte of the character holding the UTF-16 code unit offset
      # units, the last character's for one past the text, 0 on an empty
      # line.
      #: (String, Integer) -> Integer
      def column_of(text, units)
        count = 0
        last = 0
        i = 0
        while i < text.bytesize
          b = text.getbyte(i).to_i
          if (b & 0xC0) != 0x80
            return i if count >= units
            last = i
            count += b >= 0xF0 ? 2 : 1
          end
          i += 1
        end
        last
      end
    end
  end
end
