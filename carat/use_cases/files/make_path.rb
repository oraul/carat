require_relative "../../plugin_api"
require_relative "../../domain/path_policy"
require_relative "../../ports/file_port"
require_relative "../outcome"
require_relative "probe_path"

module Carat
  module UseCases
    # Creates an empty file, or a directory, at a path inside a root, after
    # every check passed, with the message of the first one that did not:
    # a usable name, the path strictly inside the root, the target absent,
    # its parent a directory, and that parent, with every symbolic link
    # resolved, the root or inside it, both resolved, so a link inside the
    # tree that leads out of it is never created through. Paths are
    # resolved against the working directory and shown relative to it in
    # messages.
    class MakePath
      attr_reader :files #: Ports::FilePort
      attr_reader :probe_path #: ProbePath

      #: (files: Ports::FilePort, probe_path: ProbePath) -> void
      def initialize(files:, probe_path:)
        @files = files
        @probe_path = probe_path
      end

      #: (String, String, bool) -> Outcome
      def call(root, path, directory)
        here = @files.cwd
        base = PluginApi::Paths.absolute(here, root)
        target = PluginApi::Paths.absolute(here, path)
        problem = Domain::PathPolicy.create_problem(path)
        return Outcome.failure(problem) unless problem.empty?
        return Outcome.failure("Outside the tree root: #{Domain::PathPolicy.shown(here, target)}") unless Domain::PathPolicy.inside?(base, target)
        return Outcome.failure("Already exists: #{Domain::PathPolicy.shown(here, target)}") if @probe_path.call(target).exists
        parent = PluginApi::Paths.dirname(target)
        return Outcome.failure("No such directory: #{Domain::PathPolicy.shown(here, parent)}") unless @probe_path.call(parent).directory
        return Outcome.failure("Outside the tree root: #{Domain::PathPolicy.shown(here, target)}") unless resolved_inside?(base, parent)
        begin
          if directory
            @files.mkdir(target)
          else
            @files.write(target, "")
          end
        rescue StandardError => error
          return Outcome.failure(error.message)
        end
        Outcome.success("")
      end

      private

      # Whether the parent, with its links resolved, is the root with its
      # links resolved or lies inside it; false when either cannot be
      # resolved.
      #: (String, String) -> bool
      def resolved_inside?(root, parent)
        real_root = ""
        real_parent = ""
        begin
          real_root = @files.real_path(root)
          real_parent = @files.real_path(parent)
        rescue StandardError
          return false
        end
        real_parent == real_root || Domain::PathPolicy.inside?(real_root, real_parent)
      end
    end
  end
end
