require_relative "../../plugin_api"
require_relative "../../domain/editor_state"
require_relative "../files/file_ops"
require_relative "boundary"

module Carat
  module UseCases
    # The file requests of the plugin API: listing a directory, stating a
    # path, and creating, renaming, and deleting entries inside a root,
    # which FileOps checks and performs. The plugin link has checked that
    # the plugin is enabled.
    class FileRequests
      # @rbs @state: Domain::EditorState
      # @rbs @file_ops: FileOps

      #: (Domain::EditorState, FileOps) -> void
      def initialize(state, file_ops)
        @state = state
        @file_ops = file_ops
      end

      #: (String, String) -> PluginApi::Response
      def list_dir(name, path)
        names = []
        begin
          names = @file_ops.list(path)
        rescue StandardError => error
          return PluginApi::Response.failure(error.message)
        end
        PluginApi::Response.listing(Boundary.copied_lines(names))
      end

      #: (String, String) -> PluginApi::FileInfo
      def stat(name, path)
        info = @file_ops.probe(path)
        return PluginApi::FileInfo.missing unless info.exists
        PluginApi::FileInfo.new(true, info.size, info.mtime, info.directory, info.symlink)
      end

      #: (String, String, String) -> PluginApi::Response
      def make_file(name, root, path)
        respond(@file_ops.make(root, path, false))
      end

      #: (String, String, String) -> PluginApi::Response
      def make_dir(name, root, path)
        respond(@file_ops.make(root, path, true))
      end

      #: (String, String, String, String) -> PluginApi::Response
      def rename_path(name, root, path, new_name)
        respond(@file_ops.rename(@state, root, path, new_name))
      end

      #: (String, String, String) -> PluginApi::Response
      def delete_path(name, root, path)
        respond(@file_ops.delete(@state, root, path))
      end

      private

      #: (Outcome) -> PluginApi::Response
      def respond(outcome)
        outcome.ok ? PluginApi::Response.success(outcome.message, 0) : PluginApi::Response.failure(outcome.message)
      end
    end
  end
end
