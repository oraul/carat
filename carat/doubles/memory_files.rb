require_relative "../ports/file_port"
require_relative "../plugin_api"
require_relative "../domain/path_info"

module Carat
  module Doubles
    # An in-memory file system: files as a hash from absolute path to text,
    # directories as a set of absolute paths, and the paths tests marked as
    # symbolic links. A relative path is resolved against the working
    # directory, "/project" unless a test moves it, so the editor's
    # relative paths and a plugin's absolute ones name the same entries.
    # Putting or writing a file creates its directories. Paths listed in
    # unwritable raise on write, so tests can exercise E212.
    class MemoryFiles < Ports::FilePort
      attr_reader :unwritable #: Array[String]

      # @rbs @files: Hash[String, String]
      # @rbs @dirs: Hash[String, String]
      # @rbs @links: Hash[String, String]
      # @rbs @cwd: String

      #: () -> void
      def initialize
        @files = {}
        @dirs = {}
        @links = {}
        @unwritable = []
        @cwd = "/project"
        @dirs["/"] = ""
        add_dirs(@cwd)
      end

      # Makes path the working directory, creating it.
      #: (String) -> void
      def move_to(path)
        @cwd = PluginApi::Paths.normalize(path)
        add_dirs(@cwd)
      end

      #: (String, String) -> void
      def put(path, text)
        k = key(path)
        add_dirs(PluginApi::Paths.dirname(k))
        @files[k] = text
      end

      #: (String) -> String?
      def get(path)
        @files[key(path)]
      end

      # Marks a path a test put or made as a symbolic link.
      #: (String) -> void
      def link(path)
        @links[key(path)] = ""
      end

      #: (String) -> bool
      def directory?(path)
        @dirs.key?(key(path))
      end

      # Returns the file's text, raising when it is absent.
      # @rbs path: String
      def read(path)
        text = @files[key(path)]
        raise ArgumentError, "no such file: #{path}" if text.nil?
        text
      end

      #: (String, String) -> void
      def write(path, text)
        raise ArgumentError, "Permission denied" if @unwritable.include?(path)
        k = key(path)
        raise ArgumentError, "Is a directory: #{path}" if @dirs.key?(k)
        add_dirs(PluginApi::Paths.dirname(k))
        @files[k] = text
      end

      # Returns whether a file or a directory is at the path.
      # @rbs path: String
      def exist?(path)
        k = key(path)
        @files.key?(k) || @dirs.key?(k)
      end

      # Returns the sorted names of the entries of a directory, raising
      # for a path that is not one, as the disk does.
      # @rbs dir: String
      def list(dir)
        k = key(dir)
        raise ArgumentError, "no such directory: #{dir}" unless @dirs.key?(k)
        children(k).sort
      end

      # Returns the PathInfo of the path: the size of a file's text, zero
      # for a directory, a zero mtime, and the flags; PathInfo.missing for
      # a path that was never made.
      # @rbs path: String
      def stat(path)
        k = key(path)
        link = @links.key?(k)
        return Domain::PathInfo.new(true, 0, 0, true, link) if @dirs.key?(k)
        text = @files[k]
        return Domain::PathInfo.missing if text.nil?
        Domain::PathInfo.new(true, text.bytesize, 0, false, link)
      end

      #: (String) -> void
      def mkdir(path)
        k = key(path)
        raise ArgumentError, "File exists: #{path}" if @files.key?(k) || @dirs.key?(k)
        raise ArgumentError, "No such file or directory: #{path}" unless @dirs.key?(PluginApi::Paths.dirname(k))
        @dirs[k] = ""
      end

      # Moves a file, or a directory with everything under it.
      #: (String, String) -> void
      def rename(from, to)
        f = key(from)
        t = key(to)
        raise ArgumentError, "No such file or directory: #{from}" unless @files.key?(f) || @dirs.key?(f)
        raise ArgumentError, "No such file or directory: #{to}" unless @dirs.key?(PluginApi::Paths.dirname(t))
        move_keys(@files, f, t)
        move_keys(@dirs, f, t)
        move_keys(@links, f, t)
      end

      #: (String) -> void
      def delete(path)
        k = key(path)
        if @dirs.key?(k)
          raise ArgumentError, "Directory not empty: #{path}" unless children(k).empty?
          @dirs.delete(k)
        elsif @files.key?(k)
          @files.delete(k)
        else
          raise ArgumentError, "No such file or directory: #{path}"
        end
        @links.delete(k)
      end

      # Returns the working directory.
      # @rbs skip
      def cwd
        @cwd
      end

      private

      #: (String) -> String
      def key(path)
        PluginApi::Paths.absolute(@cwd, path)
      end

      # Adds a directory and every directory above it.
      #: (String) -> void
      def add_dirs(dir)
        current = dir
        until @dirs.key?(current)
          @dirs[current] = ""
          current = PluginApi::Paths.dirname(current)
        end
      end

      # The names directly inside dir, from both files and directories.
      #: (String) -> Array[String]
      def children(dir)
        out = []
        @files.each_key { |path| out << PluginApi::Paths.basename(path) if path != dir && PluginApi::Paths.dirname(path) == dir }
        @dirs.each_key { |path| out << PluginApi::Paths.basename(path) if path != dir && PluginApi::Paths.dirname(path) == dir }
        out
      end

      # Renames the key from, and every key below it, to the same place
      # under to.
      #: (Hash[String, String], String, String) -> void
      def move_keys(table, from, to)
        moved = []
        table.each_key { |path| moved << path if path == from || path.start_with?(from + "/") }
        i = 0
        while i < moved.length
          old = moved[i]
          value = table.delete(old)
          table[to + old[from.length, old.length - from.length]] = value.nil? ? "" : value
          i += 1
        end
      end
    end
  end
end
