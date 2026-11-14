module Carat
  # The plugin API: the only file a compiled plugin may require. It holds
  # the values a plugin declares and receives, the host base class whose
  # methods are the requests a plugin can make, and the plugin base class
  # it subclasses. Every request and every response is a plain value with
  # no callbacks, so the same table can later serve process plugins over
  # JSON-RPC. The file requires nothing, so a plugin that requires only
  # it cannot reach an entity, a use case, or a driver.
  module PluginApi
    MAJOR = 2
    MINOR = 6
    VERSION = "2.6"

    # The priority of a status bar segment set with set_status, and the
    # highest a plugin may give with set_segment (from 2.2). When the bar
    # is narrow, segments of lower priority are dropped first; the
    # editor's own run from 20 (the encoding) to 100 (the mode).
    STATUS_PRIORITY = 10
    PRIORITY_MAX = 99

    # The events a plugin may subscribe to, by name. idle arrives with the
    # language services change, which gives the main loop an idle tick.
    EVENTS = ["buffer_open", "buffer_change", "buffer_save", "buffer_close", "buffer_rename", "cursor_move", "mode_change", "window_focus", "resize", "quit"]

    # The types an option may have. Defaults and settings are written as
    # configuration lines; values reach the plugin as text: "true" or
    # "false", digits, the word itself, or a list's words joined by
    # newlines.
    OPTION_TYPES = ["bool", "integer", "string", "list"]

    # The slots of the tab page a scratch window opens in: the left and
    # right sidebars and the bottom panel (2.4).
    SIDES = ["left", "right", "bottom"]

    # What a plugin declares. name is lowercase letters, digits, and
    # underscores starting with a letter; version is the plugin's own;
    # api_version is "major.minor" of this API; actions maps
    # "plugin.<name>.<action>" to a description; commands maps an ex
    # command name, starting with an uppercase letter, to its abbreviation
    # or ""; bindings is a list of configuration lines
    # "keymap.<mode> <keys> <action>", the action being one of the
    # plugin's actions or a key sequence (API 2.0); events is the list of
    # event names; options is a list of configuration lines
    # "plugin.<name>.<option> <value>", one default per option (API 2.0),
    # and option_types maps the same option names to "bool", "integer",
    # "string", or "list"; filetypes lists the filetypes the plugin
    # tokenizes (API 1.3), each lowercase letters, digits, and underscores
    # starting with a letter, [] for none. The host also reads events and
    # option types given as symbols, as API 1.1 spelled them. A Data value:
    # equal by value and frozen.
    class Manifest < Data.define(:name, :version, :api_version, :actions, :commands, :bindings, :events, :options, :option_types, :filetypes)
      # @rbs @name: String
      # @rbs @version: String
      # @rbs @api_version: String
      # @rbs @bindings: untyped
      # @rbs @events: untyped
      # @rbs @filetypes: untyped
      #
      # The three hashes and the options are not pinned: a pinned member
      # refuses the empty literal a plugin passes for "no commands" or "no
      # options", so their types are inferred from the manifests the
      # binary holds.

      # The description of one of the plugin's actions, or "".
      #: (String) -> String
      def describe(action)
        text = actions[action]
        text.nil? ? "" : text
      end
    end

    # One event: its name, the buffer and window ids (0 for none), the path
    # ("" for none), the cursor row and column (for resize, the rows and
    # columns of the screen; for buffer_change, the first changed row and
    # column 0), a detail (the mode name for mode_change, the old path for
    # buffer_rename, "" otherwise), and for buffer_change the number of
    # rows removed at row and the number inserted in their place (0
    # otherwise). A Data value.
    class Event < Data.define(:name, :buffer, :window, :path, :row, :col, :detail, :removed, :inserted)
      # @rbs @name: String
      # @rbs @buffer: Integer
      # @rbs @window: Integer
      # @rbs @path: String
      # @rbs @row: Integer
      # @rbs @col: Integer
      # @rbs @detail: String
      # @rbs @removed: Integer
      # @rbs @inserted: Integer

      # One line naming every field, for logs and tests.
      #: () -> String
      def to_line
        range = name == "buffer_change" ? " -#{removed} +#{inserted}" : ""
        "#{name} b#{buffer} w#{window} #{path} #{row},#{col}#{range} #{detail}".rstrip
      end
    end

    # What on_action receives: the count and register typed before the
    # key (0 and "" for none), the current buffer and window ids, the
    # buffer's path ("" for none), and the cursor. A Data value.
    class Context < Data.define(:count, :register, :buffer, :window, :path, :row, :col)
      # @rbs @count: Integer
      # @rbs @register: String
      # @rbs @buffer: Integer
      # @rbs @window: Integer
      # @rbs @path: String
      # @rbs @row: Integer
      # @rbs @col: Integer

      # The count, or the default when none was typed.
      #: (Integer) -> Integer
      def count_or(default)
        count > 0 ? count : default
      end
    end

    # What on_command receives: the name as declared, whether a bang was
    # typed, and the argument text ("" for none). A Data value.
    class Command < Data.define(:name, :bang, :args)
      # @rbs @name: String
      # @rbs @bang: bool
      # @rbs @args: String

      #: () -> bool
      def args?
        !args.empty?
      end
    end

    # One replacement of an edit request: the start row and column, the
    # exclusive end row and column, and the text to put there, which may
    # hold newlines. Rows and columns count from 0. A Data value.
    class Edit < Data.define(:from_row, :from_col, :to_row, :to_col, :text)
      # @rbs @from_row: Integer
      # @rbs @from_col: Integer
      # @rbs @to_row: Integer
      # @rbs @to_col: Integer
      # @rbs @text: String

      # An edit that replaces nothing and only inserts its text.
      #: () -> bool
      def insertion?
        from_row == to_row && from_col == to_col
      end
    end

    # The general answer to a request: whether it succeeded, a message
    # ("" for none), a number (a count, 0 when the request has none), and
    # lines (a listing, empty when the request has none). A Data value.
    class Response < Data.define(:ok, :message, :number, :lines)
      # @rbs @ok: bool
      # @rbs @message: String
      # @rbs @number: Integer
      # @rbs @lines: Array[String]

      #: (String, Integer) -> Response
      def self.success(message, number)
        Response.new(ok: true, message: message, number: number, lines: [])
      end

      #: (String) -> Response
      def self.failure(message)
        Response.new(ok: false, message: message, number: 0, lines: [])
      end

      #: (Array[String]) -> Response
      def self.listing(lines)
        Response.new(ok: true, message: "", number: lines.length, lines: lines)
      end
    end

    # The answer to a request about a window: whether it succeeded, a
    # message ("" for none), and the id of the window it is about (0 when
    # it failed or there is none). A Data value.
    class WindowResponse < Data.define(:ok, :message, :window)
      # @rbs @ok: bool
      # @rbs @message: String
      # @rbs @window: Integer

      #: (String, Integer) -> WindowResponse
      def self.success(message, window)
        WindowResponse.new(ok: true, message: message, window: window)
      end

      #: (String) -> WindowResponse
      def self.failure(message)
        WindowResponse.new(ok: false, message: message, window: 0)
      end
    end

    # Where and how a float opens (from 2.3): anchor "editor" counts row
    # and col (each -10000 to 10000) from the screen's top-left cell,
    # "cursor" from the cursor cell; height and width are its text rows
    # and columns, at least 1; the host pads the text with one column on
    # each side, inside the box; border draws a one-cell border around
    # it (in the style of option.winborder, none drawing none) with the
    # title centered on its top edge, so a bordered box is width + 4
    # columns wide under a drawn border and width + 2 under none, as
    # Host#float_frame answers; z from 0 to 1000 stacks it, higher on
    # top; enter makes it the current window. An "editor" box keeps a
    # margin of one cell from the screen's edges and is cut to fit inside
    # it; a "cursor" box is cut to the screen. A Data value.
    class FloatOptions < Data.define(:anchor, :row, :col, :height, :width, :border, :title, :z, :enter)
      # @rbs @anchor: String
      # @rbs @row: Integer
      # @rbs @col: Integer
      # @rbs @height: Integer
      # @rbs @width: Integer
      # @rbs @border: bool
      # @rbs @title: String
      # @rbs @z: Integer
      # @rbs @enter: bool

      # Options at an offset from the editor's corner with a border, no
      # title, z 50, not entered.
      #: (Integer, Integer, Integer, Integer) -> FloatOptions
      def self.at(row, col, height, width)
        FloatOptions.new(anchor: "editor", row: row, col: col, height: height, width: width, border: true, title: "", z: 50, enter: false)
      end
    end

    # The frame of a float (from 2.6): whether the request succeeded, a
    # message (the reason when it failed), the border cells on each side
    # under the current option.winborder (0 or 1), the padding columns on
    # each side, and the cells the host keeps between an "editor" box and
    # the screen's edges. A Data value.
    class FloatFrame < Data.define(:ok, :message, :edge, :padding, :margin)
      # @rbs @ok: bool
      # @rbs @message: String
      # @rbs @edge: Integer
      # @rbs @padding: Integer
      # @rbs @margin: Integer

      #: (Integer, Integer, Integer) -> FloatFrame
      def self.success(edge, padding, margin)
        FloatFrame.new(ok: true, message: "", edge: edge, padding: padding, margin: margin)
      end

      #: (String) -> FloatFrame
      def self.failure(message)
        FloatFrame.new(ok: false, message: message, edge: 0, padding: 0, margin: 0)
      end

      # The columns of a box whose text is width columns wide.
      #: (Integer) -> Integer
      def box_width(width)
        width + 2 * (edge + padding)
      end
    end

    # The answer to a request for one piece of text: whether it succeeded,
    # a message ("" for none, the reason when it failed), and the text ("" when
    # it failed). A Data value.
    class TextResponse < Data.define(:ok, :message, :text)
      # @rbs @ok: bool
      # @rbs @message: String
      # @rbs @text: String

      #: (String) -> TextResponse
      def self.success(text)
        TextResponse.new(ok: true, message: "", text: text)
      end

      #: (String) -> TextResponse
      def self.failure(message)
        TextResponse.new(ok: false, message: message, text: "")
      end
    end

    # The answer to a buffer read: ok is false, with the reason in message,
    # when there is no such buffer; otherwise the buffer id, its path (""
    # for none), copies of its lines, the cursor of the current window
    # when the buffer is the current one (0, 0 otherwise), and the modified
    # flag. A Data value.
    class BufferView < Data.define(:ok, :message, :buffer, :path, :lines, :row, :col, :modified)
      # @rbs @ok: bool
      # @rbs @message: String
      # @rbs @buffer: Integer
      # @rbs @path: String
      # @rbs @lines: Array[String]
      # @rbs @row: Integer
      # @rbs @col: Integer
      # @rbs @modified: bool

      #: (String) -> BufferView
      def self.missing(message)
        BufferView.new(ok: false, message: message, buffer: 0, path: "", lines: [], row: 0, col: 0, modified: false)
      end
    end

    # The answer to a stat: ok is false when the path cannot be read;
    # otherwise the size in bytes, the modification time in seconds,
    # whether the path is a directory (following a symbolic link), and
    # whether it is a symbolic link itself. A Data value.
    class FileInfo < Data.define(:ok, :size, :mtime, :directory, :symlink)
      # @rbs @ok: bool
      # @rbs @size: Integer
      # @rbs @mtime: Integer
      # @rbs @directory: bool
      # @rbs @symlink: bool

      #: () -> FileInfo
      def self.missing
        FileInfo.new(ok: false, size: 0, mtime: 0, directory: false, symlink: false)
      end
    end

    # What on_input receives when a prompt ends: the id the plugin gave
    # the prompt, the text typed ("" when cancelled), and whether the user
    # cancelled with Escape or a backspace on an empty line. A Data value.
    class Input < Data.define(:id, :text, :cancelled)
      # @rbs @id: String
      # @rbs @text: String
      # @rbs @cancelled: bool

      # Whether the user answered with some text.
      #: () -> bool
      def answered?
        !cancelled && !text.empty?
      end
    end

    # Pure path functions over "/"-separated text, for plugins and the
    # host alike: nothing here touches the disk. An absolute path starts
    # with "/"; normalize resolves "." and ".." and repeated slashes.
    module Paths
      #: (String) -> String
      def self.normalize(path)
        text = segments(path).join("/")
        return "/" + text if path.start_with?("/")
        text.empty? ? "." : text
      end

      # The names of a path after resolving "." and "..": a ".." at the
      # start of a relative path stays, one above the root is dropped. The
      # path is cut at each "/" by bytes, since String#split raises on a
      # name that is not UTF-8.
      #: (String) -> Array[String]
      def self.segments(path)
        out = []
        absolute = path.start_with?("/")
        size = path.bytesize
        start = 0
        while start <= size
          slash = path.byteindex("/", start)
          stop = slash.nil? ? size : slash
          piece = path.byteslice(start, stop - start).to_s
          if piece == ".."
            if !out.empty? && out[out.length - 1] != ".."
              out.pop
            elsif !absolute
              out << ".."
            end
          elsif !piece.empty? && piece != "."
            out << piece
          end
          start = stop + 1
        end
        out
      end

      #: (String, String) -> String
      def self.join(dir, name)
        return name if dir.empty?
        dir.end_with?("/") ? dir + name : dir + "/" + name
      end

      # The directory part: "/" for an entry of the root, "." for a bare
      # name. Found by bytes, as segments are, so a name that is not UTF-8
      # cuts where its slash is.
      #: (String) -> String
      def self.dirname(path)
        slash = path.byterindex("/")
        return "." if slash.nil?
        return "/" if slash == 0
        path.byteslice(0, slash).to_s
      end

      # The last name; "/" for the root itself.
      #: (String) -> String
      def self.basename(path)
        return "/" if path == "/"
        slash = path.byterindex("/")
        name = path
        name = path.byteslice(slash + 1, path.bytesize - slash - 1).to_s unless slash.nil?
        name
      end

      # The normalized absolute form of path, resolved against cwd when
      # it is relative.
      #: (String, String) -> String
      def self.absolute(cwd, path)
        path.start_with?("/") ? normalize(path) : normalize(join(cwd, path))
      end

      # The path relative to cwd when it lies below it, otherwise the path
      # itself; both are normalized absolute paths.
      #: (String, String) -> String
      def self.relative(cwd, path)
        return path unless inside?(cwd, path)
        prefix = cwd == "/" ? "/" : cwd + "/"
        path[prefix.length, path.length - prefix.length]
      end

      # Whether path lies strictly below root; both are normalized
      # absolute paths.
      #: (String, String) -> bool
      def self.inside?(root, path)
        prefix = root == "/" ? "/" : root + "/"
        path.start_with?(prefix) && path.length > prefix.length
      end
    end

    # The file-icon table, for plugins and the host alike: the icon name
    # of a file by its whole name, then by the text after its last dot,
    # "default" otherwise, and the file-icon highlight group each icon is
    # drawn in. The explorer draws its tree with it and the buffer tabs
    # their icons. The dot is found by bytes, so a name that is not UTF-8
    # finds its extension.
    module FileIcons
      NAMES = {
        "Makefile" => "makefile",
        "makefile" => "makefile",
        "GNUmakefile" => "makefile",
        ".gitignore" => "git",
        ".gitattributes" => "git",
        ".gitmodules" => "git"
      }

      EXTENSIONS = {
        "rb" => "ruby",
        "json" => "json",
        "md" => "markdown",
        "toml" => "toml",
        "sh" => "shell",
        "c" => "c",
        "h" => "c",
        "yml" => "yaml",
        "yaml" => "yaml",
        "lock" => "lock"
      }

      GROUPS = {
        "folder_closed" => "DevIconFolder",
        "folder_open" => "DevIconFolder",
        "symlink" => "DevIconSymlink",
        "ruby" => "DevIconRb",
        "json" => "DevIconJson",
        "markdown" => "DevIconMd",
        "toml" => "DevIconToml",
        "makefile" => "DevIconMakefile",
        "shell" => "DevIconSh",
        "c" => "DevIconC",
        "yaml" => "DevIconYml",
        "git" => "DevIconGitIgnore",
        "lock" => "DevIconLock",
        "default" => "DevIconDefault"
      }

      # The icon name of a file name, the last segment of a path.
      #: (String) -> String
      def self.file_type(name)
        whole = NAMES[name]
        return whole unless whole.nil?
        dot = name.byterindex(".")
        return "default" if dot.nil? || dot == 0
        by_extension = EXTENSIONS[name.byteslice(dot + 1, name.bytesize - dot - 1).to_s]
        by_extension.nil? ? "default" : by_extension
      end

      # The name of the file-icon group of an icon name, DevIconDefault
      # for one without its own.
      #: (String) -> String
      def self.group_of(icon)
        group = GROUPS[icon]
        group.nil? ? "DevIconDefault" : group
      end
    end

    # The requests a plugin can make, one method each. The host hands every
    # plugin its own instance at activation, so the host knows which plugin
    # owns a scratch buffer, a sign, a status segment, or an option. Every
    # method here raises; the editor's host overrides them all. Buffers and
    # windows are addressed by id, the number the editor gives each when it
    # is created and never gives another; 0 means the current one.
    class Host
      # Returns a BufferView of the buffer with the id.
      # @rbs buffer: Integer
      def read_buffer(buffer)
        raise NotImplementedError, "Host#read_buffer"
      end

      # Applies the Edit values to the buffer as one validated transaction
      # and returns a Response whose number is the count; one bad item
      # refuses them all and changes nothing.
      # @rbs buffer: Integer
      # @rbs edits: Array[untyped]
      def edit_buffer(buffer, edits)
        raise NotImplementedError, "Host#edit_buffer"
      end

      # Moves the cursor of the current window, clamped into the buffer,
      # and returns a Response.
      # @rbs row: Integer
      # @rbs col: Integer
      def move_cursor(row, col)
        raise NotImplementedError, "Host#move_cursor"
      end

      # Opens, or refreshes and focuses, the plugin's scratch buffer with
      # that title in the tab page's "left" or "right" sidebar, width
      # columns wide, or its "bottom" panel (2.4), width rows high, unless
      # the slot's size option is set, holding the lines, with its own
      # keymap built from bindings, keymap lines
      # "keymap.<mode> <keys> <action>" as in the manifest. A new buffer's syntax is the plugin's name when the
      # manifest declares that filetype (API 2.1), so the plugin tokenizes
      # its own lines. Returns a WindowResponse with the window's id.
      # @rbs title: String
      # @rbs side: String
      # @rbs width: Integer
      # @rbs lines: Array[String]
      # @rbs bindings: untyped
      def open_scratch(title, side, width, lines, bindings)
        raise NotImplementedError, "Host#open_scratch"
      end

      # Replaces every line of the plugin's scratch buffer with that title
      # and returns a Response.
      # @rbs title: String
      # @rbs lines: Array[String]
      def set_scratch_lines(title, lines)
        raise NotImplementedError, "Host#set_scratch_lines"
      end

      # Closes the window showing the plugin's scratch buffer with that
      # title and returns a Response.
      # @rbs title: String
      def close_scratch(title)
        raise NotImplementedError, "Host#close_scratch"
      end

      # Makes the window with the id current, and its tab page with it, and
      # returns a WindowResponse.
      # @rbs window: Integer
      def focus_window(window)
        raise NotImplementedError, "Host#focus_window"
      end

      # Shows the file at path in the window with the id, as :e does there,
      # then makes the window current, and returns a WindowResponse with
      # the opened message.
      # @rbs window: Integer
      # @rbs path: String
      def open_file(window, path)
        raise NotImplementedError, "Host#open_file"
      end

      # Splits the window with the id, horizontally or vertically, and
      # shows the file at path, taken as it is, in the new window, which
      # becomes current; returns a WindowResponse with its id.
      # @rbs window: Integer
      # @rbs path: String
      # @rbs vertical: bool
      def open_in_split(window, path, vertical)
        raise NotImplementedError, "Host#open_in_split"
      end

      # Opens a tab page after the current one showing the file at path,
      # taken as it is; returns a WindowResponse with its window's id.
      # @rbs path: String
      def open_in_tab(path)
        raise NotImplementedError, "Host#open_in_tab"
      end

      # Shows text in the message row, as an error when error is true, and
      # returns a Response.
      # @rbs text: String
      # @rbs error: bool
      def message(text, error)
        raise NotImplementedError, "Host#message"
      end

      # Sets the plugin's status bar segment at STATUS_PRIORITY, ""
      # removing it, and returns a Response.
      # @rbs text: String
      def set_status(text)
        raise NotImplementedError, "Host#set_status"
      end

      # Sets the plugin's status bar segment with a priority from 0 to
      # PRIORITY_MAX, "" removing it, and returns a Response, failed for a
      # priority out of range (from 2.2).
      # @rbs text: String
      # @rbs priority: Integer
      def set_segment(text, priority)
        raise NotImplementedError, "Host#set_segment"
      end

      # Places the icon named icon as the plugin's sign on row of the
      # buffer and returns a Response.
      # @rbs buffer: Integer
      # @rbs row: Integer
      # @rbs icon: String
      def place_sign(buffer, row, icon)
        raise NotImplementedError, "Host#place_sign"
      end

      # Removes the signs the plugin placed in the buffer and returns a
      # Response whose number is how many there were.
      # @rbs buffer: Integer
      def clear_signs(buffer)
        raise NotImplementedError, "Host#clear_signs"
      end

      # Runs an ex command line and returns its outcome as a Response.
      # @rbs text: String
      def run_ex(text)
        raise NotImplementedError, "Host#run_ex"
      end

      # Returns a Response whose lines are the sorted entries of the
      # directory, failed when it cannot be read.
      # @rbs path: String
      def list_dir(path)
        raise NotImplementedError, "Host#list_dir"
      end

      # Returns a Response whose lines are the paths, relative to root, of
      # the regular files below it, recursively, each directory's entries
      # sorted (API 2.5): an entry whose name is in ignore is neither
      # listed nor entered, a link to a directory is never entered, and a
      # link whose target is not inside root, every link resolved, is
      # skipped. Failed when root cannot be read; at 100,000 files the
      # listing stops with a message.
      # @rbs root: String
      # @rbs ignore: Array[String]
      def list_files(root, ignore)
        raise NotImplementedError, "Host#list_files"
      end

      # Returns a Response whose lines are the first rows lines of the
      # regular file at path, without line endings, read only when it
      # holds at most 256 KiB (API 2.5); failed with the file system's
      # message, and for rows below 1 or above 1000.
      # @rbs path: String
      # @rbs rows: Integer
      def read_file(path, rows)
        raise NotImplementedError, "Host#read_file"
      end

      # Returns a FileInfo for the path.
      # The base answers a missing FileInfo rather than raising: at Spinel
      # f34005bf a versioned entry joins a raising base's nil into the
      # overrides' return, and the result's readers go unresolved
      # (spinel-notes, Known miscompilations).
      # @rbs path: String
      def stat(path)
        FileInfo.missing
      end

      # Returns a TextResponse with the glyph of the named icon in the
      # configured icon set, failed for an unknown name.
      # The base answers a failure rather than raising, as stat does.
      # @rbs name: String
      def icon(name)
        TextResponse.failure("Host#icon is not implemented")
      end

      # Returns a TextResponse with the plugin's option value as text,
      # failed for an unknown name.
      # @rbs name: String
      def option(name)
        raise NotImplementedError, "Host#option"
      end

      # Returns a TextResponse with the absolute path of the editor's
      # working directory.
      # @rbs skip
      def working_directory
        raise NotImplementedError, "Host#working_directory"
      end

      # Returns a WindowResponse with the window to open a file in: the
      # previously used window of the current tab page when it shows a
      # file buffer, otherwise the first window in layout order that does,
      # 0 when none does.
      # @rbs skip
      def editing_window
        raise NotImplementedError, "Host#editing_window"
      end

      # Returns a WindowResponse with the window of the current tab page
      # showing the plugin's scratch buffer with that title, 0 when none
      # does.
      # @rbs title: String
      def scratch_window(title)
        raise NotImplementedError, "Host#scratch_window"
      end

      # Opens a float (from 2.3) showing the lines in a scratch buffer the
      # plugin owns, never listed nor written, placed as the FloatOptions
      # say over the current tab page, and returns a WindowResponse with
      # its window id; refused for an unknown anchor, an offset or a z out
      # of range, a size below 1, or a tab page holding 16 floats.
      # @rbs options: FloatOptions
      # @rbs lines: Array[String]
      def open_float(options, lines)
        raise NotImplementedError, "Host#open_float"
      end

      # Moves the plugin's float with the window id to another offset from
      # its anchor and returns a Response (from 2.3); refused for an
      # offset out of range.
      # @rbs window: Integer
      # @rbs row: Integer
      # @rbs col: Integer
      def move_float(window, row, col)
        raise NotImplementedError, "Host#move_float"
      end

      # Returns a FloatFrame (from 2.6): the frame a float the plugin opens
      # with that border takes under the current border style, and the
      # margin the host keeps around every box.
      # @rbs border: bool
      def float_frame(border)
        raise NotImplementedError, "Host#float_frame"
      end

      # Closes the plugin's float with the window id, 0 for the current
      # window, and returns a Response (from 2.3); the window under a
      # focused float becomes current.
      # @rbs window: Integer
      def close_float(window)
        raise NotImplementedError, "Host#close_float"
      end

      # Creates an empty file at path, which must lie strictly inside root,
      # and returns a Response; refused when the name is empty, the path
      # exists, or its directory does not.
      # @rbs root: String
      # @rbs path: String
      def make_file(root, path)
        raise NotImplementedError, "Host#make_file"
      end

      # Creates a directory at path inside root, refused as make_file is,
      # and returns a Response.
      # @rbs root: String
      # @rbs path: String
      def make_dir(root, path)
        raise NotImplementedError, "Host#make_dir"
      end

      # Renames the entry at path inside root to name in the same directory
      # and returns a Response; refused for an empty name, a name with a
      # "/", a missing entry, or an existing target. Open buffers of the
      # entry follow it.
      # @rbs root: String
      # @rbs path: String
      # @rbs name: String
      def rename_path(root, path, name)
        raise NotImplementedError, "Host#rename_path"
      end

      # Deletes the file or empty directory at path inside root and
      # returns a Response; a directory with entries is refused. An open
      # buffer of the file stays and becomes modified.
      # @rbs root: String
      # @rbs path: String
      def delete_path(root, path)
        raise NotImplementedError, "Host#delete_path"
      end

      # Opens a prompt in the command-line row: text in place of ":", then
      # initial, edited with the command-line keys. Enter or a cancel
      # arrives later as an Input with the id through on_input. Returns a
      # Response, failed while another prompt is open.
      # @rbs id: String
      # @rbs text: String
      # @rbs initial: String
      def prompt(id, text, initial)
        raise NotImplementedError, "Host#prompt"
      end

      # Opens a prompt as prompt does whose every change of text arrives
      # as an Input through on_prompt_change after the key, and whose
      # bindings, keymap lines of command-line mode bound to the plugin's
      # actions, answer before the command-line keymap while it is open
      # (API 2.5). Returns a Response, failed while another prompt is
      # open.
      # @rbs id: String
      # @rbs text: String
      # @rbs initial: String
      # @rbs bindings: Array[String]
      def live_prompt(id, text, initial, bindings)
        raise NotImplementedError, "Host#live_prompt"
      end

      # Closes the plugin's open prompt without an on_input and returns
      # to normal mode (API 2.5). Returns a Response, failed when the
      # plugin holds no open prompt.
      # @rbs skip
      def close_prompt
        raise NotImplementedError, "Host#close_prompt"
      end

      # Returns a Response whose number is the id of the syntax highlight
      # group ("Comment", "String", ... "Todo", "Error") or the file-icon
      # group ("DevIconDefault", "DevIconRb", ... "DevIconLock", API 2.1)
      # with that name, failed with "No highlight group named x" for any
      # other name. A tokenizer resolves its groups once, in activate, and
      # gives the ids in its tokens.
      # @rbs name: String
      def syntax_group(name)
        raise NotImplementedError, "Host#syntax_group"
      end
    end

    # What a compiled plugin implements. manifest is required; the rest
    # do nothing unless overridden. The host calls activate once with the
    # plugin's Host when the plugin is enabled, deactivate when the editor
    # quits, on_event for every subscribed event, on_action for every
    # action of the plugin, on_command for every ex command of the
    # plugin, on_input when a prompt the plugin opened ends,
    # on_prompt_change when a live prompt's text changed, and tokenize
    # for each line the editor highlights in a filetype the manifest
    # declares. A plugin
    # that raises anything in any of them, an unimplemented method's
    # NotImplementedError and a stack overflow included, is disabled.
    class Plugin
      # Returns the plugin's Manifest.
      # @rbs skip
      def manifest
        raise NotImplementedError, "Plugin#manifest"
      end

      #: (Host) -> void
      def activate(host)
      end

      #: () -> void
      def deactivate
      end

      #: (Event) -> void
      def on_event(event)
      end

      #: (String, Context) -> void
      def on_action(name, context)
      end

      #: (Command) -> void
      def on_command(command)
      end

      #: (Input) -> void
      def on_input(input)
      end

      # The text of a live prompt the plugin opened changed (API 2.5).
      #: (Input) -> void
      def on_prompt_change(input)
      end

      # Tokenizes one line of a buffer whose filetype the manifest
      # declares: text is the line, a copy the host reuses, so it is valid
      # during the call only; state is the state at the start of the line,
      # 0 for the first line of the buffer, or what this method returned
      # for the line before. Appends the tokens to tokens, an empty integer
      # array, as flat triples of start column, length, and group id, in
      # code point columns, with ids from Host#syntax_group, and returns
      # the state at the end of the line, a non-negative integer the plugin
      # encodes as it likes: the host only compares and passes it on.
      # @rbs filetype: String
      # @rbs text: String
      # @rbs state: Integer
      # @rbs tokens: Array[Integer]
      def tokenize(filetype, text, state, tokens)
        raise NotImplementedError, "Plugin#tokenize"
      end
    end
  end
end
