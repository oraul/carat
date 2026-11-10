require_relative "../../plugin_api"
require_relative "../../ports/file_port"
require_relative "../files/probe_path"
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
    # check and perform. The plugin link has checked that the plugin is
    # enabled. The use cases have no reader named as a request.
    class FileRequests
      MAX_FILES = 100_000
      READ_LIMIT = 262_144
      MAX_ROWS = 1000
      private_constant :MAX_FILES, :READ_LIMIT, :MAX_ROWS

      attr_reader :files #: Ports::FilePort
      attr_reader :probe_path #: ProbePath

      # @rbs @make_path: MakePath
      # @rbs @rename_path: RenamePath
      # @rbs @delete_path: DeletePath
      # @rbs @list_tree: ListTree

      #: (files: Ports::FilePort, probe_path: ProbePath, make_path: MakePath, rename_path: RenamePath, delete_path: DeletePath, list_tree: ListTree) -> void
      def initialize(files:, probe_path:, make_path:, rename_path:, delete_path:, list_tree:)
        @files = files
        @probe_path = probe_path
        @make_path = make_path
        @rename_path = rename_path
        @delete_path = delete_path
        @list_tree = list_tree
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

      private

      #: (String, Integer) -> Array[String]
      def first_lines(text, rows)
        lines = [""]
        lines.clear
        at = 0
        size = text.bytesize
        while at < size && lines.length < rows
          stop = text.byteindex("\n", at)
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
