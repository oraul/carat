require_relative "../../plugin_api"
require_relative "node"
require_relative "file_icons"

module Carat
  module Plugins
    module Explorer
      # The tree model: the root, the expanded directories, whether hidden
      # entries show, the names never shown, the marked path (the file of
      # the current editing window), and the visible lines of the last
      # build. build lists every expanded directory through the host,
      # directories first and then files, each group by name ignoring
      # case; lines renders them with icons from the host's table.
      class Tree
        # @rbs @root: String
        # @rbs @expanded: Hash[String, String]
        # @rbs @show_hidden: bool
        # @rbs @ignore: Array[String]
        # @rbs @marked: String
        # @rbs @nodes: Array[untyped]

        #: (String, bool, Array[String]) -> void
        def initialize(root, show_hidden, ignore)
          @root = PluginApi::Paths.normalize(root)
          @expanded = {}
          @show_hidden = show_hidden
          @ignore = ignore
          @marked = ""
          @nodes = []
        end

        #: () -> String
        def root
          @root
        end

        #: () -> String
        def marked
          @marked
        end

        #: () -> bool
        def show_hidden?
          @show_hidden
        end

        #: () -> void
        def toggle_hidden
          @show_hidden = !@show_hidden
        end

        # Makes a directory the root; the expanded set is kept.
        #: (String) -> void
        def set_root(path)
          @root = PluginApi::Paths.normalize(path)
        end

        #: (String) -> bool
        def expanded?(path)
          path == @root || @expanded.key?(path)
        end

        #: (String) -> void
        def expand(path)
          @expanded[path] = ""
        end

        #: (String) -> void
        def collapse(path)
          @expanded.delete(path)
        end

        #: (String) -> void
        def toggle(path)
          if @expanded.key?(path)
            collapse(path)
          else
            expand(path)
          end
        end

        #: (String) -> void
        def mark(path)
          @marked = path
        end

        # Expands every directory between the root and path; false, with
        # nothing changed, when path is not inside the root.
        #: (String) -> bool
        def reveal(path)
          return false unless PluginApi::Paths.inside?(@root, path)
          dir = PluginApi::Paths.dirname(path)
          while dir != @root && PluginApi::Paths.inside?(@root, dir)
            expand(dir)
            dir = PluginApi::Paths.dirname(dir)
          end
          true
        end

        # An entry was renamed: the expanded directories and the mark under
        # the old path move to the new one.
        #: (String, String) -> void
        def moved(from, to)
          keys = []
          @expanded.each_key { |path| keys << path if path == from || path.start_with?(from + "/") }
          i = 0
          while i < keys.length
            @expanded.delete(keys[i])
            @expanded[to + keys[i][from.length, keys[i].length - from.length]] = ""
            i += 1
          end
          @marked = to + @marked[from.length, @marked.length - from.length] if @marked == from || @marked.start_with?(from + "/")
        end

        # Lists the root and every expanded directory below it again.
        #: (PluginApi::Host) -> void
        def build(host)
          @nodes = []
          @nodes << Node.new(@root, PluginApi::Paths.basename(@root), 0, true, false)
          walk(host, @root, 1)
        end

        #: () -> Integer
        def count
          @nodes.length
        end

        #: (Integer) -> Node
        def node(i)
          @nodes[i]
        end

        # The node on a row, or nil past the last line.
        #: (Integer) -> Node?
        def at(row)
          return nil if row < 0 || row >= @nodes.length
          node(row)
        end

        # The row of a path, or -1 when it is not visible.
        #: (String) -> Integer
        def row_of(path)
          i = 0
          while i < @nodes.length
            return i if node(i).path == path
            i += 1
          end
          -1
        end

        # The row of the directory holding the entry on row, the root's row
        # for a top-level entry, -1 for the root itself.
        #: (Integer) -> Integer
        def parent_row(row)
          n = at(row)
          return -1 if n.nil? || n.root?
          row_of(PluginApi::Paths.dirname(n.path))
        end

        # The lines: a marker column holding the current icon on the marked
        # entry, two spaces per level, the icon, a space, and the name.
        #: (PluginApi::Host) -> Array[String]
        def lines(host)
          out = []
          current = host.icon("current")
          i = 0
          while i < @nodes.length
            n = node(i)
            mark = n.path == @marked ? current : " "
            icon = host.icon(FileIcons.name_for(n.name, n.directory, expanded?(n.path), n.symlink))
            out << mark + ("  " * n.depth) + icon + " " + n.name
            i += 1
          end
          out
        end

        private

        # Adds the entries of dir at depth, each followed by its own entries
        # when it is an expanded directory.
        #: (PluginApi::Host, String, Integer) -> void
        def walk(host, dir, depth)
          entries = children(host, dir, depth)
          i = 0
          while i < entries.length
            n = child(entries, i)
            @nodes << n
            walk(host, n.path, depth + 1) if n.directory && @expanded.key?(n.path)
            i += 1
          end
        end

        # The visible entries of dir as nodes, directories first, each
        # group sorted by name ignoring case.
        #: (PluginApi::Host, String, Integer) -> Array[untyped]
        def children(host, dir, depth)
          out = []
          listing = host.list_dir(dir)
          return out unless listing.ok
          names = sorted(visible(listing.lines))
          dirs = []
          files = []
          i = 0
          while i < names.length
            path = PluginApi::Paths.join(dir, names[i])
            info = host.stat(path)
            n = Node.new(path, names[i], depth, info.ok && info.directory, info.ok && info.symlink)
            if n.directory
              dirs << n
            else
              files << n
            end
            i += 1
          end
          i = 0
          while i < dirs.length
            out << dirs[i]
            i += 1
          end
          i = 0
          while i < files.length
            out << files[i]
            i += 1
          end
          out
        end

        #: (Array[untyped], Integer) -> Node
        def child(list, i)
          list[i]
        end

        # The names left after dropping hidden ones (unless shown) and
        # ignored ones.
        #: (Array[String]) -> Array[String]
        def visible(names)
          out = []
          i = 0
          while i < names.length
            name = names[i]
            hidden = name.start_with?(".") && !@show_hidden
            out << name unless hidden || @ignore.include?(name)
            i += 1
          end
          out
        end

        #: (Array[String]) -> Array[String]
        def sorted(names)
          names.sort { |a, b| compare(a, b) }
        end

        # Orders by name ignoring case, then by the exact name.
        #: (String, String) -> Integer
        def compare(a, b)
          da = a.downcase
          db = b.downcase
          return -1 if da < db
          return 1 if da > db
          return -1 if a < b
          return 1 if a > b
          0
        end
      end
    end
  end
end
