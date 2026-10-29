module Carat
  # The plugin API: the only file a compiled plugin may require. It holds
  # the values a plugin declares and receives, the host base class whose
  # methods are the requests a plugin can make, and the plugin base class
  # it subclasses. Every request and every response is a plain value with
  # no callbacks, so the same table can later serve process plugins over
  # JSON-RPC. The file requires nothing, so a plugin that requires only
  # it cannot reach an entity, a use case, or a driver.
  module PluginApi
    MAJOR = 1
    MINOR = 0
    VERSION = "1.0"

    # The events a plugin may subscribe to. idle arrives with the language
    # services change, which gives the main loop an idle tick.
    EVENTS = [:buffer_open, :buffer_change, :buffer_save, :cursor_move, :mode_change, :window_focus, :resize, :quit]

    # The types an option may have; values travel as text on both sides:
    # "true" or "false", digits, the string itself, or list items joined
    # by newlines.
    OPTION_TYPES = [:bool, :integer, :string, :list]

    # What a plugin declares. name is lowercase letters, digits, and
    # underscores starting with a letter; version is the plugin's own;
    # api_version is "major.minor" of this API; actions maps
    # "plugin.<name>.<action>" to a description; commands maps an ex
    # command name, starting with an uppercase letter, to its abbreviation
    # or ""; bindings is the JSON keymap shape, a hash from mode name to a
    # hash from key notation to an action name or key sequence; events is
    # the list of event symbols; options maps an option name to its default
    # as text and option_types the same names to :bool, :integer, :string,
    # or :list. A Data value: equal by value and frozen.
    class Manifest < Data.define(:name, :version, :api_version, :actions, :commands, :bindings, :events, :options, :option_types)
      # @rbs @name: String
      # @rbs @version: String
      # @rbs @api_version: String
      # @rbs @bindings: untyped
      # @rbs @events: untyped
      #
      # The four hashes are not pinned: a pinned hash member refuses the
      # empty literal a plugin passes for "no commands" or "no options",
      # so their types are inferred from the manifests the binary holds.

      # The description of one of the plugin's actions, or "".
      #: (String) -> String
      def describe(action)
        text = actions[action]
        text.nil? ? "" : text
      end
    end

    # One event: its name, the buffer and window numbers (positions from 1,
    # 0 for none), the path ("" for none), the cursor row and column (for
    # :resize, the rows and columns of the screen), and a detail (the mode
    # name for :mode_change, "" otherwise). A Data value.
    class Event < Data.define(:name, :buffer, :window, :path, :row, :col, :detail)
      # @rbs @name: Symbol
      # @rbs @buffer: Integer
      # @rbs @window: Integer
      # @rbs @path: String
      # @rbs @row: Integer
      # @rbs @col: Integer
      # @rbs @detail: String

      # One line naming every field, for logs and tests.
      #: () -> String
      def to_line
        "#{name} b#{buffer} w#{window} #{path} #{row},#{col} #{detail}".rstrip
      end
    end

    # What on_action receives: the count and register typed before the
    # key (0 and "" for none), the current buffer and window numbers, the
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
    # ("" for none), a number (a window number or a count, 0 when the
    # request has none), and lines (a listing, empty when the request has
    # none). A Data value.
    class Response < Data.define(:ok, :message, :number, :lines)
      # @rbs @ok: bool
      # @rbs @message: String
      # @rbs @number: Integer
      # @rbs @lines: Array[String]

      #: (String, Integer) -> Response
      def self.success(message, number)
        Response.new(true, message, number, [])
      end

      #: (String) -> Response
      def self.failure(message)
        Response.new(false, message, 0, [])
      end

      #: (Array[String]) -> Response
      def self.listing(lines)
        Response.new(true, "", lines.length, lines)
      end
    end

    # The answer to a buffer read: ok is false when there is no such
    # buffer; otherwise the buffer number, its path ("" for none), copies
    # of its lines, the cursor of the current window when the buffer is
    # the current one (0, 0 otherwise), and the modified flag. A Data
    # value.
    class BufferView < Data.define(:ok, :number, :path, :lines, :row, :col, :modified)
      # @rbs @ok: bool
      # @rbs @number: Integer
      # @rbs @path: String
      # @rbs @lines: Array[String]
      # @rbs @row: Integer
      # @rbs @col: Integer
      # @rbs @modified: bool

      #: () -> BufferView
      def self.missing
        BufferView.new(false, 0, "", [], 0, 0, false)
      end
    end

    # The answer to a stat: ok is false when the path cannot be read;
    # otherwise the size in bytes, the modification time in seconds, and
    # whether the path is a directory. A Data value.
    class FileInfo < Data.define(:ok, :size, :mtime, :directory)
      # @rbs @ok: bool
      # @rbs @size: Integer
      # @rbs @mtime: Integer
      # @rbs @directory: bool

      #: () -> FileInfo
      def self.missing
        FileInfo.new(false, 0, 0, false)
      end
    end

    # The requests a plugin can make, one method each. The host hands every
    # plugin its own instance at activation, so the host knows which plugin
    # owns a scratch buffer, a sign, a status segment, or an option. Every
    # method here raises; the editor's host overrides them all. Buffer
    # numbers are positions in the buffer list from 1 and window numbers
    # positions in the current tab page's layout order from 1, 0 meaning
    # the current one; both move when buffers or windows come and go.
    class Host
      # Returns a BufferView of buffer number.
      # @rbs number: Integer
      def read_buffer(number)
        raise NotImplementedError, "Host#read_buffer"
      end

      # Applies the Edit values to buffer number as one validated batch and
      # returns a Response; one bad edit refuses them all.
      # @rbs number: Integer
      # @rbs edits: Array[untyped]
      def edit_buffer(number, edits)
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
      # that title in a fixed-width window at the :left or :right edge of
      # the tab page, holding the lines, with its own keymap built from
      # bindings in the JSON keymap shape. Returns a Response whose number
      # is the window number.
      # @rbs title: String
      # @rbs side: Symbol
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

      # Makes window number current and returns a Response.
      # @rbs number: Integer
      def focus_window(number)
        raise NotImplementedError, "Host#focus_window"
      end

      # Shows the file at path in window number, as :e does there, and
      # returns a Response with the opened message.
      # @rbs number: Integer
      # @rbs path: String
      def open_file(number, path)
        raise NotImplementedError, "Host#open_file"
      end

      # Shows text in the message row, as an error when error is true, and
      # returns a Response.
      # @rbs text: String
      # @rbs error: bool
      def message(text, error)
        raise NotImplementedError, "Host#message"
      end

      # Sets the plugin's status line segment, "" removing it, and returns
      # a Response.
      # @rbs text: String
      def set_status(text)
        raise NotImplementedError, "Host#set_status"
      end

      # Places the icon named icon as a sign on row of buffer number and
      # returns a Response.
      # @rbs number: Integer
      # @rbs row: Integer
      # @rbs icon: String
      def place_sign(number, row, icon)
        raise NotImplementedError, "Host#place_sign"
      end

      # Removes the signs the plugin placed in buffer number and returns a
      # Response.
      # @rbs number: Integer
      def clear_signs(number)
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

      # Returns a FileInfo for the path.
      # @rbs path: String
      def stat(path)
        raise NotImplementedError, "Host#stat"
      end

      # Returns the glyph of the named icon in the configured icon set.
      # @rbs name: String
      def icon(name)
        raise NotImplementedError, "Host#icon"
      end

      # Returns the plugin's option value as text, "" for an unknown name.
      # @rbs name: String
      def option(name)
        raise NotImplementedError, "Host#option"
      end
    end

    # What a compiled plugin implements. manifest is required; the rest
    # do nothing unless overridden. The host calls activate once with the
    # plugin's Host when the plugin is enabled, deactivate when the editor
    # quits, on_event for every subscribed event, on_action for every
    # action of the plugin, and on_command for every ex command of the
    # plugin. A plugin that raises in any of them is disabled.
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
    end
  end
end
