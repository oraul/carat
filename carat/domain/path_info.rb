module Carat
  module Domain
    # What the file port says about a path: whether anything is there (a
    # link to nothing included), its size in bytes, its modification time
    # in seconds, whether it is a directory (following a link), whether it
    # is a symbolic link itself, and whether it is a regular file (following
    # a link), not a directory, a FIFO, a device, or a socket. A Data value.
    class PathInfo < Data.define(:exists, :size, :mtime, :directory, :symlink, :regular)
      # @rbs @exists: bool
      # @rbs @size: Integer
      # @rbs @mtime: Integer
      # @rbs @directory: bool
      # @rbs @symlink: bool
      # @rbs @regular: bool

      # The most bytes a file opened in a buffer may hold, 64 MiB.
      BUFFER_LIMIT = 67_108_864

      #: () -> PathInfo
      def self.missing
        PathInfo.new(exists: false, size: 0, mtime: 0, directory: false, symlink: false, regular: false)
      end

      # Whether the path is a directory and not a link to one.
      #: () -> bool
      def real_directory?
        directory && !symlink
      end

      # Vim's message for a path to read that is not there, not a regular
      # file, or over limit bytes, "" for one that may be read; a path that
      # could not be stated, as one removed meanwhile, is E484. The read
      # checks again on the opened file, for a path swapped after the stat.
      #: (String, Integer) -> String
      def refusal(path, limit)
        return "E484: Can't open file #{path}" unless exists
        return "\"#{path}\" is a directory" if directory
        return "\"#{path}\" is not a file" unless regular
        return "E484: Can't open file #{path}: File too large" if size > limit
        ""
      end
    end
  end
end
