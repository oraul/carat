require_relative "../../plugin_api"
require_relative "../../domain/editor_state"
require_relative "../../domain/buffer"
require_relative "../../domain/buffer_list"
require_relative "../../domain/definition_request"
require_relative "../../domain/filetype"
require_relative "../../domain/jump_list"
require_relative "../../domain/messages"
require_relative "../../domain/options"
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
    # working directory with every link resolved, and otherwise shows the
    # listed buffer of the file or opens it as a listed read-only file
    # buffer named as :e would name it, which has its tab like any file
    # buffer and is never written (SaveFile). The position left joins the
    # jump list once the target shows. A peek
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
        unless absolute(current.path_text) == absolute(path)
          return Outcome.failure(Domain::Messages::E37) if current.modified? && !current.scratch?
          held = listed_for(path)
          tabbed = !held.nil? && !held.tabless?
          outcome = inside?(path) ? @open_file.call(state, open_path(path)) : view(state, path)
          return outcome unless outcome.ok
          @buffers.hand_tab(current, state.window.buffer) if !tabbed && state.options.jumptab == Domain::Options::JUMPTAB_REPLACE
        end
        @jumps.push(from_id, from_row, from_col)
        place(state.window, line, character)
        outcome
      end

      # Shows a file outside the project: its listed buffer, or a new
      # read-only file buffer of it.
      #: (Domain::EditorState, String) -> Outcome
      def view(state, path)
        listed = listed_for(path)
        unless listed.nil?
          @buffers.load(listed)
          shown = "\"#{listed.path_text}\""
          shown += " [readonly]" if listed.readonly
          return Outcome.success(shown)
        end
        problem = @probe_path.call(path).refusal(path, Domain::PathInfo::BUFFER_LIMIT)
        return Outcome.failure(problem) unless problem.empty?
        text = read(path, Domain::PathInfo::BUFFER_LIMIT)
        return Outcome.failure("E484: Can't open file #{path}") if text.nil?
        name = Domain::PathPolicy.shown(@files.cwd, path)
        buffer = Domain::Buffer.from_text(text, name)
        buffer.readonly = true
        @buffers.load(buffer)
        Outcome.success("\"#{name}\" [readonly] #{buffer.line_count}L, #{text.bytesize}B")
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

      # The listed file buffer of the file, read-only or not, or nil.
      #: (String) -> Domain::Buffer?
      def listed_for(path)
        i = 0
        while i < @buffers.count
          candidate = @buffers.buffer_at(i)
          return candidate if !candidate.scratch? && absolute(candidate.path_text) == absolute(path)
          i += 1
        end
        nil
      end

      # The path OpenFile is given: a listed buffer's own, so it is shown
      # and not read again, else the target relative to the working
      # directory, as :e would name it.
      #: (String) -> String
      def open_path(path)
        listed = listed_for(path)
        return listed.path_text unless listed.nil?
        Domain::PathPolicy.shown(@files.cwd, path)
      end

      # Whether the target lies below the working directory, also once
      # every link of it is resolved.
      #: (String) -> bool
      def inside?(path)
        cwd = @files.cwd
        Domain::PathPolicy.inside?(cwd, path) && @resolve_inside.call(cwd, path, path).ok
      end

      # The normalized absolute form of a path, "." and ".." resolved, so
      # a buffer named ./a.rb is the file of a target /project/a.rb; ""
      # for a buffer with no file.
      #: (String) -> String
      def absolute(path)
        return "" if path.empty?
        PluginApi::Paths.absolute(@files.cwd, path)
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

      # The cursor column, a code point index, of the character holding the
      # UTF-16 code unit offset units (two units for a four-byte sequence),
      # the last character's for one past the text, 0 on an empty line.
      #: (String, Integer) -> Integer
      def column_of(text, units)
        count = 0
        column = -1
        i = 0
        while i < text.bytesize
          b = text.getbyte(i).to_i
          if (b & 0xC0) != 0x80
            column += 1
            return column if count >= units
            count += b >= 0xF0 ? 2 : 1
          end
          i += 1
        end
        column < 0 ? 0 : column
      end
    end
  end
end
