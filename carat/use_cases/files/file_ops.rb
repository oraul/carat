require_relative "../../plugin_api"
require_relative "../../domain/editor_state"
require_relative "../../domain/path_info"
require_relative "../../domain/path_policy"
require_relative "../../ports/file_port"
require_relative "../outcome"

module Carat
  module UseCases
    # Creates, renames, and deletes files and directories inside a root,
    # after every check passed, with the message of the first one that did
    # not: the path strictly inside the root, a usable name, the source
    # present, the target absent, the parent a directory, and a directory
    # to delete empty. The open buffers follow a rename, and a buffer of a
    # deleted file becomes modified. Paths are resolved against the
    # working directory and shown relative to it in messages. It is the
    # one place the use cases ask the port about a path (probe).
    class FileOps
      # @rbs @files: Ports::FilePort

      #: (Ports::FilePort) -> void
      def initialize(files)
        @files = files
      end

      #: () -> String
      def cwd
        @files.cwd
      end

      # What the port says about the path; a path it cannot stat is
      # missing.
      #: (String) -> Domain::PathInfo
      def probe(path)
        info = nil
        begin
          info = @files.stat(path)
        rescue StandardError
          return Domain::PathInfo.missing
        end
        Domain::PathInfo.new(true, field(info, "size"), field(info, "mtime"), field(info, "directory") == 1, field(info, "symlink") == 1)
      end

      # The sorted entry names of a directory; raises as the port does.
      #: (String) -> Array[String]
      def list(path)
        @files.list(path)
      end

      # Whether two paths name the same file once resolved against the
      # working directory.
      #: (String, String) -> bool
      def same_path?(a, b)
        here = cwd
        PluginApi::Paths.absolute(here, a) == PluginApi::Paths.absolute(here, b)
      end

      # Creates an empty file, or a directory, at path inside root.
      #: (String, String, bool) -> Outcome
      def make(root, path, directory)
        here = cwd
        base = PluginApi::Paths.absolute(here, root)
        target = PluginApi::Paths.absolute(here, path)
        problem = Domain::PathPolicy.create_problem(path)
        return Outcome.failure(problem) unless problem.empty?
        return Outcome.failure("Outside the tree root: #{shown(here, target)}") unless Domain::PathPolicy.inside?(base, target)
        return Outcome.failure("Already exists: #{shown(here, target)}") if probe(target).exists
        parent = PluginApi::Paths.dirname(target)
        return Outcome.failure("No such directory: #{shown(here, parent)}") unless probe(parent).directory
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

      # Renames the entry at path inside root to name in its directory,
      # then lets the listed buffers of it, or under it, follow.
      #: (Domain::EditorState, String, String, String) -> Outcome
      def rename(state, root, path, name)
        here = cwd
        base = PluginApi::Paths.absolute(here, root)
        source = PluginApi::Paths.absolute(here, path)
        problem = Domain::PathPolicy.rename_problem(name)
        return Outcome.failure(problem) unless problem.empty?
        return Outcome.failure("Outside the tree root: #{shown(here, source)}") unless Domain::PathPolicy.inside?(base, source)
        return Outcome.failure("No such file or directory: #{shown(here, source)}") unless probe(source).exists
        target = PluginApi::Paths.join(PluginApi::Paths.dirname(source), name)
        return Outcome.failure("Already exists: #{shown(here, target)}") if probe(target).exists
        begin
          @files.rename(source, target)
        rescue StandardError => error
          return Outcome.failure(error.message)
        end
        follow_rename(state, here, source, target)
        Outcome.success("")
      end

      # Deletes the file or empty directory at path inside root; a listed
      # buffer of the file stays and becomes modified.
      #: (Domain::EditorState, String, String) -> Outcome
      def delete(state, root, path)
        here = cwd
        base = PluginApi::Paths.absolute(here, root)
        target = PluginApi::Paths.absolute(here, path)
        return Outcome.failure("Outside the tree root: #{shown(here, target)}") unless Domain::PathPolicy.inside?(base, target)
        info = probe(target)
        return Outcome.failure("No such file or directory: #{shown(here, target)}") unless info.exists
        return Outcome.failure("Directory not empty: #{shown(here, target)}") if info.real_directory? && !empty_directory?(target)
        begin
          @files.delete(target)
        rescue StandardError => error
          return Outcome.failure(error.message)
        end
        mark_deleted(state, here, target)
        Outcome.success("")
      end

      # Every listed file buffer of the renamed path, or under it, takes
      # the new path, relative to the working directory when it was.
      #: (Domain::EditorState, String, String, String) -> void
      def follow_rename(state, here, from, to)
        i = 0
        while i < state.buffer_count
          b = state.buffer_at(i)
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

      # A listed buffer of the deleted file stays and becomes modified: no
      # saved text matches it any more.
      #: (Domain::EditorState, String, String) -> void
      def mark_deleted(state, here, target)
        i = 0
        while i < state.buffer_count
          b = state.buffer_at(i)
          path = b.path
          b.mark_unsaved if !path.nil? && !b.scratch? && PluginApi::Paths.absolute(here, path) == target
          i += 1
        end
      end

      private

      #: (String, String) -> String
      def shown(here, path)
        Domain::PathPolicy.shown(here, path)
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

      # An integer field of the port's stat hash, 0 when it is missing.
      #: (untyped, String) -> Integer
      def field(info, key)
        return 0 unless info.is_a?(Hash)
        value = info[key]
        value.is_a?(Integer) ? value : 0
      end
    end
  end
end
