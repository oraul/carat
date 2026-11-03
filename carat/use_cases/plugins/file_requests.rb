require_relative "../../plugin_api"
require_relative "../../ports/file_port"
require_relative "../files/probe_path"
require_relative "../files/make_path"
require_relative "../files/rename_path"
require_relative "../files/delete_path"
require_relative "boundary"

module Carat
  module UseCases
    # The file requests of the plugin API: listing a directory, stating a
    # path through ProbePath, and creating, renaming, and deleting
    # entries inside a root, which MakePath, RenamePath, and DeletePath
    # check and perform. The plugin link has checked that the plugin is
    # enabled. The use cases have no reader named as a request.
    class FileRequests
      attr_reader :files #: Ports::FilePort
      attr_reader :probe_path #: ProbePath

      # @rbs @make_path: MakePath
      # @rbs @rename_path: RenamePath
      # @rbs @delete_path: DeletePath

      #: (files: Ports::FilePort, probe_path: ProbePath, make_path: MakePath, rename_path: RenamePath, delete_path: DeletePath) -> void
      def initialize(files:, probe_path:, make_path:, rename_path:, delete_path:)
        @files = files
        @probe_path = probe_path
        @make_path = make_path
        @rename_path = rename_path
        @delete_path = delete_path
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

      #: (Outcome) -> PluginApi::Response
      def respond(outcome)
        outcome.ok ? PluginApi::Response.success(outcome.message, 0) : PluginApi::Response.failure(outcome.message)
      end
    end
  end
end
