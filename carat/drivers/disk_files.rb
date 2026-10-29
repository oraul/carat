require_relative "../ports/file_port"

module Carat
  module Drivers
    # The file system through File and Dir.
    class DiskFiles < Ports::FilePort
      # Returns the file's text.
      # @rbs path: String
      def read(path)
        File.read(path)
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

      # Returns size, mtime, and the directory and symlink flags as a hash
      # of integers. A link whose target is missing reads as an empty link
      # instead of raising; a missing path raises.
      # @rbs path: String
      def stat(path)
        link = File.symlink?(path)
        if link && !File.exist?(path)
          return { "size" => 0, "mtime" => 0, "directory" => 0, "symlink" => 1 }
        end
        {
          "size" => File.size(path),
          "mtime" => File.mtime(path).to_i,
          "directory" => File.directory?(path) ? 1 : 0,
          "symlink" => link ? 1 : 0
        }
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
    end
  end
end
