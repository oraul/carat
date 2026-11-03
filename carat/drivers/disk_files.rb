require_relative "../ports/file_port"
require_relative "../domain/path_info"

module Carat
  module Drivers
    # The file system through File and Dir.
    class DiskFiles < Ports::FilePort
      # Returns the regular file's text, of at most limit bytes. The open
      # does not block, so a FIFO is refused instead of waiting for a
      # writer, and the kind is checked on the opened file, so a path
      # swapped after a caller's stat is refused too. One byte past the
      # limit is read to tell a file of exactly the limit from a longer
      # one; the bytes are UTF-8, as File.read gives them.
      # @rbs path: String
      # @rbs limit: Integer
      def read(path, limit)
        file = File.open(path, File::RDONLY | File::NONBLOCK)
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

      #: (String, String) -> void
      def write(path, text)
        File.write(path, text)
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

      # Returns the PathInfo of the path: a link whose target is missing
      # reads as an empty link, and a missing path as PathInfo.missing.
      # The pinned Spinel answers File.file? true for a FIFO and a device,
      # so regular comes from File.stat, which follows a link.
      # @rbs path: String
      def stat(path)
        link = File.symlink?(path)
        return Domain::PathInfo.new(exists: true, size: 0, mtime: 0, directory: false, symlink: true, regular: false) if link && !File.exist?(path)
        return Domain::PathInfo.missing unless link || File.exist?(path)
        Domain::PathInfo.new(exists: true, size: File.size(path), mtime: File.mtime(path).to_i, directory: File.directory?(path), symlink: link, regular: File.stat(path).file?)
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
    end
  end
end
