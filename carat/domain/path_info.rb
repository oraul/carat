module Carat
  module Domain
    # What the file port says about a path: whether anything is there (a
    # link to nothing included), its size in bytes, its modification time
    # in seconds, whether it is a directory (following a link), and whether
    # it is a symbolic link itself. A Data value.
    class PathInfo < Data.define(:exists, :size, :mtime, :directory, :symlink)
      # @rbs @exists: bool
      # @rbs @size: Integer
      # @rbs @mtime: Integer
      # @rbs @directory: bool
      # @rbs @symlink: bool

      #: () -> PathInfo
      def self.missing
        PathInfo.new(false, 0, 0, false, false)
      end

      # Whether the path is a directory and not a link to one.
      #: () -> bool
      def real_directory?
        directory && !symlink
      end
    end
  end
end
