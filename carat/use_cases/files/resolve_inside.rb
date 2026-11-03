require_relative "../../domain/path_policy"
require_relative "../../ports/file_port"
require_relative "../outcome"

module Carat
  module UseCases
    # Refuses a file operation on a path whose directory, with every
    # symbolic link resolved, is neither the root with its links resolved
    # nor inside it, or when either cannot be resolved, with "Outside the
    # tree root: path", so nothing is changed through a link inside the
    # tree that leads out of it; succeeds otherwise. MakePath asks it about
    # the parent of the entry it creates, RenamePath and DeletePath about
    # the directory of the entry they change; the entry itself may be a
    # link, which they act on and never follow.
    class ResolveInside
      attr_reader :files #: Ports::FilePort

      #: (files: Ports::FilePort) -> void
      def initialize(files:)
        @files = files
      end

      #: (String, String, String) -> Outcome
      def call(root, dir, path)
        real_root = ""
        real_dir = ""
        begin
          real_root = @files.real_path(root)
          real_dir = @files.real_path(dir)
        rescue StandardError
          return outside(path)
        end
        return Outcome.success("") if real_dir == real_root || Domain::PathPolicy.inside?(real_root, real_dir)
        outside(path)
      end

      private

      #: (String) -> Outcome
      def outside(path)
        Outcome.failure("Outside the tree root: #{Domain::PathPolicy.shown(@files.cwd, path)}")
      end
    end
  end
end
