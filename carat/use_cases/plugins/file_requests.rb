require_relative "../../plugin_api"
require_relative "../../ports/file_port"
require_relative "../../ports/process_port"
require_relative "../files/probe_path"
require_relative "../../domain/utf8"
require_relative "../files/make_path"
require_relative "../files/rename_path"
require_relative "../files/delete_path"
require_relative "../files/list_tree"
require_relative "boundary"

module Carat
  module UseCases
    # The file requests of the plugin API: listing a directory, listing
    # the files below a root through ListTree (at most MAX_FILES), reading
    # the first rows of a file of at most READ_LIMIT bytes, stating a
    # path through ProbePath, and creating, renaming, and deleting
    # entries inside a root, which MakePath, RenamePath, and DeletePath
    # check and perform, and running a program on the PATH through the
    # process port's capture, never a path, so not one a cloned project
    # carries, and only while the working directory is trusted
    # (Domain::TrustedRoots, which the plugin host decides on activation),
    # with git's lazy fetch off and every git transport refused
    # (PROGRAM_ENVIRONMENT: an empty GIT_ALLOW_PROTOCOL allows none,
    # whatever the configuration, also for a git older than 2.44, which
    # ignores GIT_NO_LAZY_FETCH), so a cloned repository's promisor
    # remote, upload-pack, or ssh command cannot run. The plugin link
    # has checked that the plugin is enabled. The use cases have no reader named as a request.
    class FileRequests
      MAX_FILES = 100_000
      READ_LIMIT = 262_144
      MAX_ROWS = 262_144
      PROGRAM_ENVIRONMENT = { "GIT_NO_LAZY_FETCH" => "1", "GIT_ALLOW_PROTOCOL" => "" }
      private_constant :MAX_FILES, :READ_LIMIT, :MAX_ROWS, :PROGRAM_ENVIRONMENT

      attr_reader :files #: Ports::FilePort
      attr_reader :probe_path #: ProbePath
      attr_reader :processes #: Ports::ProcessPort

      # @rbs @make_path: MakePath
      # @rbs @rename_path: RenamePath
      # @rbs @delete_path: DeletePath
      # @rbs @list_tree: ListTree
      # @rbs @trusted: bool

      #: (files: Ports::FilePort, processes: Ports::ProcessPort, probe_path: ProbePath, make_path: MakePath, rename_path: RenamePath, delete_path: DeletePath, list_tree: ListTree) -> void
      def initialize(files:, processes:, probe_path:, make_path:, rename_path:, delete_path:, list_tree:)
        @files = files
        @processes = processes
        @probe_path = probe_path
        @make_path = make_path
        @rename_path = rename_path
        @delete_path = delete_path
        @list_tree = list_tree
        @trusted = false
      end

      # Whether programs may run: the working directory is under a trusted
      # root. False until the plugin host decides it on activation.
      #: (bool) -> void
      def trusted=(value)
        @trusted = value
      end

      #: (String, String) -> PluginApi::Response
      def list_dir(name, path)
        names = []
        begin
          names = @files.list(path)
        rescue StandardError => error
          return PluginApi::Response.failure(error.message)
        end
        PluginApi::Response.listing(Boundary.copied_lines(names))
      end

      # The files below the root; a listing that reached MAX_FILES says so.
      #: (String, String, Array[String]) -> PluginApi::Response
      def list_files(name, root, ignore)
        paths = [""]
        paths.clear
        begin
          paths = @list_tree.call(root, Boundary.copied_lines(ignore), MAX_FILES)
        rescue StandardError => error
          return PluginApi::Response.failure(error.message)
        end
        message = paths.length >= MAX_FILES ? "Listed the first #{MAX_FILES} files" : ""
        PluginApi::Response.new(ok: true, message: message, number: paths.length, lines: paths)
      end

      # The first rows lines of the file, cut at each newline with a
      # carriage return before it dropped, so a long file is not split
      # whole.
      #: (String, String, Integer) -> PluginApi::Response
      def read_file(name, path, rows)
        return PluginApi::Response.failure("rows must be 1 to #{MAX_ROWS}") if rows < 1 || rows > MAX_ROWS
        text = ""
        begin
          text = @files.read(path, READ_LIMIT)
        rescue StandardError => error
          return PluginApi::Response.failure(error.message)
        end
        PluginApi::Response.listing(first_lines(text, rows))
      end

      #: (String, String) -> PluginApi::FileInfo
      def stat(name, path)
        info = @probe_path.call(path)
        return PluginApi::FileInfo.missing unless info.exists
        PluginApi::FileInfo.new(ok: true, size: info.size, mtime: info.mtime, directory: info.directory, symlink: info.symlink)
      end

      #: (String, String, String) -> PluginApi::Response
      def make_file(name, root, path)
        respond(@make_path.call(root, path, false))
      end

      #: (String, String, String) -> PluginApi::Response
      def make_dir(name, root, path)
        respond(@make_path.call(root, path, true))
      end

      #: (String, String, String, String) -> PluginApi::Response
      def rename_path(name, root, path, new_name)
        respond(@rename_path.call(root, path, new_name))
      end

      #: (String, String, String) -> PluginApi::Response
      def delete_path(name, root, path)
        respond(@delete_path.call(root, path))
      end

      # Runs the program after the checks, refused outside a trusted root,
      # with PROGRAM_ENVIRONMENT added to its environment; the words are
      # copied, so the plugin cannot change them while they run. A program
      # killed at its deadline fails apart from one that cannot start, so
      # a plugin can tell a slow program from a missing one.
      #: (String, Array[String]) -> PluginApi::TextResponse
      def run_program(name, argv)
        return PluginApi::TextResponse.failure("a program runs only under a root of language.trusted_roots") unless @trusted
        why = program_refusal(argv)
        return PluginApi::TextResponse.failure(why) unless why.empty?
        words = argv.map { |word| word.dup }
        output = @processes.capture(words, PROGRAM_ENVIRONMENT)
        return PluginApi::TextResponse.failure("#{words[0]} ran past 2 seconds") if output.nil? && @processes.timed_out?
        return PluginApi::TextResponse.failure("cannot run #{words[0]}") if output.nil?
        return PluginApi::TextResponse.failure("#{words[0]} answered bytes that are not UTF-8") unless output.valid_encoding?
        PluginApi::TextResponse.success(output.dup)
      end

      private

      # Why the words are not run, "" when they may be.
      #: (Array[String]) -> String
      def program_refusal(argv)
        return "no program to run" if argv.empty?
        argv.each do |word|
          return "an empty word cannot be run" if word.empty?
          return "a word holding NUL cannot be run" if word.include?("\0")
        end
        return "#{argv[0]}: the program must be a name on the PATH" if argv[0].include?("/")
        ""
      end

      #: (String, Integer) -> Array[String]
      def first_lines(text, rows)
        lines = [""]
        lines.clear
        at = 0
        size = text.bytesize
        while at < size && lines.length < rows
          stop = text.byteindex("\n", Domain::Utf8.boundary(text, at))
          stop = size if stop.nil?
          finish = stop
          finish -= 1 if finish > at && text.getbyte(finish - 1).to_i == 13
          lines << text.byteslice(at, finish - at).to_s
          at = stop + 1
        end
        lines
      end

      #: (Outcome) -> PluginApi::Response
      def respond(outcome)
        outcome.ok ? PluginApi::Response.success(outcome.message, 0) : PluginApi::Response.failure(outcome.message)
      end
    end
  end
end
