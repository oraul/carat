require_relative "../../plugin_api"
require_relative "../../domain/buffer_list"
require_relative "../../domain/path_policy"
require_relative "../../ports/file_port"
require_relative "../outcome"
require_relative "probe_path"

module Carat
  module UseCases
    # Renames the entry at a path inside a root to a name in its
    # directory, after every check passed, with the message of the first
    # one that did not: a usable name, the source strictly inside the
    # root and present, and the target absent. The listed buffers of the
    # entry, or under it, follow the rename. Paths are resolved against
    # the working directory and shown relative to it in messages.
    class RenamePath
      attr_reader :files #: Ports::FilePort
      attr_reader :buffers #: Domain::BufferList
      attr_reader :probe_path #: ProbePath

      #: (files: Ports::FilePort, buffers: Domain::BufferList, probe_path: ProbePath) -> void
      def initialize(files:, buffers:, probe_path:)
        @files = files
        @buffers = buffers
        @probe_path = probe_path
      end

      #: (String, String, String) -> Outcome
      def call(root, path, name)
        here = @files.cwd
        base = PluginApi::Paths.absolute(here, root)
        source = PluginApi::Paths.absolute(here, path)
        problem = Domain::PathPolicy.rename_problem(name)
        return Outcome.failure(problem) unless problem.empty?
        return Outcome.failure("Outside the tree root: #{Domain::PathPolicy.shown(here, source)}") unless Domain::PathPolicy.inside?(base, source)
        return Outcome.failure("No such file or directory: #{Domain::PathPolicy.shown(here, source)}") unless @probe_path.call(source).exists
        target = PluginApi::Paths.join(PluginApi::Paths.dirname(source), name)
        return Outcome.failure("Already exists: #{Domain::PathPolicy.shown(here, target)}") if @probe_path.call(target).exists
        begin
          @files.rename(source, target)
        rescue StandardError => error
          return Outcome.failure(error.message)
        end
        follow(here, source, target)
        Outcome.success("")
      end

      private

      # Every listed file buffer of the renamed path, or under it, takes
      # the new path, relative to the working directory when it was.
      #: (String, String, String) -> void
      def follow(here, from, to)
        i = 0
        while i < @buffers.count
          b = @buffers.buffer_at(i)
          path = b.path
          unless path.nil? || b.scratch?
            abs = PluginApi::Paths.absolute(here, path)
            if abs == from || abs.start_with?(from + "/")
              moved = to + abs[from.length, abs.length - from.length]
              b.rename(path.start_with?("/") ? moved : PluginApi::Paths.relative(here, moved))
            end
          end
          i += 1
        end
      end
    end
  end
end
