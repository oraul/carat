require_relative "../ports/file_port"
require_relative "../plugin_api"
require_relative "../domain/path_info"

module Carat
  module Doubles
    # An in-memory file system: files as a hash from absolute path to text,
    # directories as a set of absolute paths, the paths tests marked as
    # symbolic links (with their targets, when a test gave one), and the
    # files tests marked as special, a FIFO or a device. A relative path is resolved against the working
    # directory, "/project" unless a test moves it (the home directory is
    # "/home/user" unless a test moves it), so the editor's
    # relative paths and a plugin's absolute ones name the same entries.
    # Putting or writing a file creates its directories. Paths listed in
    # unwritable raise on write, so tests can exercise E212.
    class MemoryFiles < Ports::FilePort
      attr_reader :unwritable #: Array[String]

      # @rbs @files: Hash[String, String]
      # @rbs @dirs: Hash[String, String]
      # @rbs @links: Hash[String, String]
      # @rbs @specials: Hash[String, String]
      # @rbs @cwd: String
      # @rbs @home: String

      #: () -> void
      def initialize
        @files = {}
        @dirs = {}
        @links = {}
        @specials = {}
        @unwritable = []
        @cwd = "/project"
        @home = "/home/user"
        @dirs["/"] = ""
        add_dirs(@cwd)
        add_dirs(@home)
      end

      # Makes path the home directory, creating it; "" means none.
      #: (String) -> void
      def move_home(path)
        if path.empty?
          @home = ""
          return
        end
        @home = PluginApi::Paths.normalize(path)
        add_dirs(@home)
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

      # Marks a path a test put or made as a symbolic link to target, which
      # real_path follows; reads and writes still use the path itself.
      #: (String, String) -> void
      def link_to(path, target)
        @links[key(path)] = key(target)
      end

      # Puts an empty file at path that is not a regular one, as a FIFO or
      # a device is: stat says so and read refuses it.
      #: (String) -> void
      def special(path)
        put(path, "")
        @specials[key(path)] = ""
      end

      #: (String) -> bool
      def directory?(path)
        @dirs.key?(key(path))
      end

      # Returns the file's text, raising when it is absent, a directory,
      # special, or longer than limit, with the driver's messages.
      # @rbs path: String
      # @rbs limit: Integer
      def read(path, limit)
        k = key(path)
        raise IOError, "Is a directory" if @dirs.key?(k)
        text = @files[k]
        raise ArgumentError, "no such file: #{path}" if text.nil?
        raise IOError, "Not a regular file" if @specials.key?(k)
        raise IOError, "File too large" if text.bytesize > limit
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
        return Domain::PathInfo.new(exists: true, size: 0, mtime: 0, directory: true, symlink: link, regular: false) if @dirs.key?(k)
        text = @files[k]
        return Domain::PathInfo.missing if text.nil?
        Domain::PathInfo.new(exists: true, size: text.bytesize, mtime: 0, directory: false, symlink: link, regular: !@specials.key?(k))
      end

      # Returns the path with the links a test gave targets replaced by
      # their targets, one level each, from the root down; raises when
      # nothing is there.
      # @rbs path: String
      def real_path(path)
        current = "/"
        rest = key(path)
        while rest.length > 1
          cut = rest.index("/", 1)
          name = cut.nil? ? rest[1, rest.length - 1].to_s : rest[1, cut - 1].to_s
          rest = cut.nil? ? "/" : rest[cut, rest.length - cut].to_s
          current = current == "/" ? "/#{name}" : "#{current}/#{name}"
          target = @links[current].to_s
          current = target unless target.empty?
        end
        raise ArgumentError, "No such file or directory: #{path}" unless @files.key?(current) || @dirs.key?(current)
        current
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
        move_keys(@specials, f, t)
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
        @specials.delete(k)
      end

      # Returns the working directory.
      # @rbs skip
      def cwd
        @cwd
      end

      # Returns the home directory, "/home/user" unless a test moves it.
      # @rbs skip
      def home
        @home
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
