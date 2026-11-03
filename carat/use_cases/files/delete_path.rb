require_relative "../../plugin_api"
require_relative "../../domain/buffer_list"
require_relative "../../domain/path_policy"
require_relative "../../ports/file_port"
require_relative "../outcome"
require_relative "probe_path"
require_relative "resolve_inside"

module Carat
  module UseCases
    # Deletes the file or empty directory at a path inside a root, after
    # every check passed, with the message of the first one that did not:
    # the path strictly inside the root, present, its directory, with
    # every symbolic link resolved, the root or inside it, both resolved,
    # so a link inside the tree that leads out of it is never deleted
    # through, and an empty directory when it is one. A link is removed,
    # never followed. A listed buffer of the file stays and becomes
    # modified. Paths are resolved against the working directory and
    # shown relative to it in messages.
    class DeletePath
      attr_reader :files #: Ports::FilePort
      attr_reader :buffers #: Domain::BufferList
      attr_reader :probe_path #: ProbePath
      attr_reader :resolve_inside #: ResolveInside

      #: (files: Ports::FilePort, buffers: Domain::BufferList, probe_path: ProbePath, resolve_inside: ResolveInside) -> void
      def initialize(files:, buffers:, probe_path:, resolve_inside:)
        @files = files
        @buffers = buffers
        @probe_path = probe_path
        @resolve_inside = resolve_inside
      end

      #: (String, String) -> Outcome
      def call(root, path)
        here = @files.cwd
        base = PluginApi::Paths.absolute(here, root)
        target = PluginApi::Paths.absolute(here, path)
        return Outcome.failure("Outside the tree root: #{Domain::PathPolicy.shown(here, target)}") unless Domain::PathPolicy.inside?(base, target)
        info = @probe_path.call(target)
        return Outcome.failure("No such file or directory: #{Domain::PathPolicy.shown(here, target)}") unless info.exists
        resolved = @resolve_inside.call(base, PluginApi::Paths.dirname(target), target)
        return resolved unless resolved.ok
        return Outcome.failure("Directory not empty: #{Domain::PathPolicy.shown(here, target)}") if info.real_directory? && !empty_directory?(target)
        begin
          @files.delete(target)
        rescue StandardError => error
          return Outcome.failure(error.message)
        end
        mark_deleted(here, target)
        Outcome.success("")
      end

      private

      # A listed buffer of the deleted file stays and becomes modified: no
      # saved text matches it any more.
      #: (String, String) -> void
      def mark_deleted(here, target)
        i = 0
        while i < @buffers.count
          b = @buffers.buffer_at(i)
          path = b.path
          b.mark_unsaved if !path.nil? && !b.scratch? && PluginApi::Paths.absolute(here, path) == target
          i += 1
        end
      end

      #: (String) -> bool
      def empty_directory?(dir)
        names = []
        begin
          names = @files.list(dir)
        rescue StandardError
          return true
        end
        names.empty?
      end
    end
  end
end
