require_relative "../ports/file_port"
require_relative "../domain/path_info"

module Carat
  module Drivers
    # The file system through File and Dir.
    class DiskFiles < Ports::FilePort
      # Returns the regular file's text, of at most limit bytes. The open
      # does not block, so a FIFO is refused instead of waiting for a
      # writer, and the kind is judged on the opened descriptor, so a path
      # swapped after a caller's stat, or after the open, is refused too.
      # One byte past the limit is read to tell a file of exactly the
      # limit from a longer one; the bytes are UTF-8, as File.read gives
      # them.
      # @rbs path: String
      # @rbs limit: Integer
      def read(path, limit)
        read_open(path, File::RDONLY | File::NONBLOCK, limit)
      end

      # Returns the text as read does, opened with NOFOLLOW, so the open
      # itself fails when path is a symbolic link.
      # @rbs path: String
      # @rbs limit: Integer
      def read_no_link(path, limit)
        read_open(path, File::RDONLY | File::NONBLOCK | File::NOFOLLOW, limit)
      end

      #: (String, String) -> void
      def write(path, text)
        File.write(path, text)
      end

      # Creates the empty file with O_CREAT and O_EXCL, which fail on any
      # entry at path, a dangling link included, and never follow a final
      # link, and O_NOFOLLOW besides, so what it makes is always a new
      # regular file at path.
      #: (String) -> void
      def create(path)
        File.open(path, File::WRONLY | File::CREAT | File::EXCL | File::NOFOLLOW).close
      end

      # Returns whether path exists.
      # @rbs path: String
      def exist?(path)
        File.exist?(path)
      end

      # Returns the sorted entry names of a directory.
      # @rbs dir: String
      def list(dir)
        Dir.children(dir).sort
      end

      # Returns the sorted names of at most limit entries, read one at a
      # time through Dir#read, which stops at the limit, "." and ".."
      # left out.
      # @rbs dir: String
      # @rbs limit: Integer
      def list_first(dir, limit)
        names = []
        handle = Dir.open(dir)
        begin
          while names.length < limit
            name = handle.read
            break if name.nil?
            names << name unless name == "." || name == ".."
          end
        ensure
          handle.close
        end
        names.sort
      end

      # Returns the PathInfo of the path from File.symlink?, which reads
      # the link itself, and one File.stat, which follows it: a link whose
      # target is missing, or that cannot be followed, reads as an empty
      # link, and a missing path as PathInfo.missing. The pinned Spinel
      # answers File.file? true for a FIFO and a device, so regular comes
      # from the stat (docs/spinel-notes.md).
      # @rbs path: String
      def stat(path)
        link = File.symlink?(path)
        begin
          info = File.stat(path)
        rescue StandardError
          return link ? Domain::PathInfo.new(exists: true, size: 0, mtime: 0, directory: false, symlink: true, regular: false) : Domain::PathInfo.missing
        end
        Domain::PathInfo.new(exists: true, size: info.size, mtime: info.mtime.to_i, directory: info.directory?, symlink: link, regular: info.file?)
      end

      # Returns the path with every link resolved, through File.realpath.
      # @rbs path: String
      def real_path(path)
        File.realpath(path)
      end

      #: (String) -> void
      def mkdir(path)
        Dir.mkdir(path)
      end

      #: (String, String) -> void
      def rename(from, to)
        File.rename(from, to)
      end

      # A real directory is removed with rmdir, which refuses one with
      # entries; anything else, a link to a directory included, is
      # unlinked, so a link is never followed.
      #: (String) -> void
      def delete(path)
        if File.directory?(path) && !File.symlink?(path)
          Dir.rmdir(path)
        else
          File.delete(path)
        end
      end

      # Returns the working directory.
      # @rbs skip
      def cwd
        Dir.pwd
      end

      # Returns HOME from the environment, "" when it is unset or not an
      # absolute path.
      # @rbs skip
      def home
        value = ENV["HOME"].to_s
        value.start_with?("/") ? value : ""
      end

      private

      # Opens path with the flags and returns the regular file's text, of at
      # most limit bytes, judging the kind on the opened descriptor.
      # IO.sysopen is a plain open(2): File.open would wait for a FIFO's
      # writer while other threads run, whatever O_NONBLOCK asked. The
      # handle IO.for_fd wraps has no path, so its stat is an fstat(2) of
      # the descriptor, where a File's stat reads its path again
      # (docs/spinel-notes.md).
      #: (String, Integer, Integer) -> String
      def read_open(path, flags, limit)
        file = IO.for_fd(IO.sysopen(path, flags))
        begin
          info = file.stat
          raise IOError, "Is a directory" if info.directory?
          raise IOError, "Not a regular file" unless info.file?
          chunk = file.read(limit + 1)
          return +"" if chunk.nil?
          raise IOError, "File too large" if chunk.bytesize > limit
          chunk.force_encoding(Encoding::UTF_8)
        ensure
          file.close
        end
      end
    end
  end
end
