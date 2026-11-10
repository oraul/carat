require_relative "../../plugin_api"
require_relative "../../domain/path_info"
require_relative "../../ports/file_port"

module Carat
  module UseCases
    # The regular files below a root, for the plugins' list_files request:
    # their paths relative to the root, depth first, each directory's
    # names in the port's sorted order, at most limit of them. A name in
    # the ignore list is neither listed nor entered. A symbolic link is
    # never entered, so the walk cannot loop and lists every file once
    # under its real directory; a link to a regular file is listed only
    # when its target, every link resolved, is strictly inside the root
    # with its links resolved. A directory below the root that cannot be
    # read is skipped; a root that cannot be resolved or read raises.
    class ListTree
      attr_reader :files #: Ports::FilePort

      #: (files: Ports::FilePort) -> void
      def initialize(files:)
        @files = files
      end

      #: (String, Array[String], Integer) -> Array[String]
      def call(root, ignore, limit)
        real_root = @files.real_path(root)
        names = @files.list(root)
        out = [""]
        out.clear
        walk(root, "", names, ignore, real_root, limit, out)
      end

      private

      # Appends the files of the directory to out and returns it, which
      # the caller assigns (docs/spinel-notes.md, appends to an array
      # passed in).
      #: (String, String, Array[String], Array[String], String, Integer, Array[String]) -> Array[String]
      def walk(dir, prefix, names, ignore, real_root, limit, out)
        i = 0
        while i < names.length && out.length < limit
          name = names[i]
          i += 1
          out = visit(dir, prefix, name, ignore, real_root, limit, out) unless ignore.include?(name)
        end
        out
      end

      # Appends the entry, or the files below it, to out and returns it.
      #: (String, String, String, Array[String], String, Integer, Array[String]) -> Array[String]
      def visit(dir, prefix, name, ignore, real_root, limit, out)
        path = PluginApi::Paths.join(dir, name)
        relative = prefix.empty? ? name : "#{prefix}/#{name}"
        info = probe(path)
        if info.symlink
          out << relative if info.regular && inside?(path, real_root)
        elsif info.directory
          out = walk(path, relative, listing(path), ignore, real_root, limit, out)
        elsif info.regular
          out << relative
        end
        out
      end

      # What the port says about the path, missing when it cannot stat it.
      #: (String) -> Domain::PathInfo
      def probe(path)
        begin
          return @files.stat(path)
        rescue StandardError
          return Domain::PathInfo.missing
        end
      end

      # The directory's names, none when it cannot be read.
      #: (String) -> Array[String]
      def listing(dir)
        names = [""]
        names.clear
        begin
          names = @files.list(dir)
        rescue StandardError
          return names
        end
        names
      end

      # Whether the link's target, every link resolved, lies strictly
      # inside the resolved root; false when it cannot be resolved.
      #: (String, String) -> bool
      def inside?(path, real_root)
        real = ""
        begin
          real = @files.real_path(path)
        rescue StandardError
          return false
        end
        PluginApi::Paths.inside?(real_root, real)
      end
    end
  end
end
