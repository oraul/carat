require_relative "../../plugin_api"
require_relative "../../domain/editor_state"
require_relative "../../domain/buffer"
require_relative "../../domain/keymap"
require_relative "../../domain/command"
require_relative "../../domain/ex_command"
require_relative "../../ports/file_port"
require_relative "../outcome"
require_relative "../files/open_file"
require_relative "../files/file_ops"
require_relative "../windows/close_window"
require_relative "../windows/split_window"
require_relative "../windows/open_tab"
require_relative "plugin_entry"
require_relative "plugin_registry"
require_relative "plugin_router"
require_relative "plugin_events"
require_relative "buffer_requests"
require_relative "window_requests"
require_relative "file_requests"
require_relative "ui_requests"
require_relative "plugin_link"

module Carat
  module UseCases
    # The plugin host as the rest of the editor sees it: it registers and
    # activates the compiled plugins, routes plugin actions, ex commands,
    # and prompt answers to them, and delivers events, through the
    # registry, the router, and the events it is built from; each plugin
    # gets a PluginLink over the four request families. Events caused
    # during a plugin call are delivered after the outermost call, so
    # every entry point that may call a plugin ends by flushing them when
    # no plugin call is in progress any more. ExecuteEx is attached after
    # construction because it routes plugin commands here while the
    # plugins run ex command strings through it.
    class PluginHost
      # @rbs @state: Domain::EditorState
      # @rbs @registry: PluginRegistry
      # @rbs @router: PluginRouter
      # @rbs @events: PluginEvents
      # @rbs @buffers: BufferRequests
      # @rbs @windows: WindowRequests
      # @rbs @files: FileRequests
      # @rbs @ui: UiRequests

      #: (Domain::EditorState, Ports::FilePort, OpenFile, CloseWindow, Domain::Keymap, String) -> void
      def initialize(state, files, open_file, close_window, keymap, leader)
        @state = state
        file_ops = FileOps.new(files)
        @registry = PluginRegistry.new(state, keymap, leader, close_window)
        @router = PluginRouter.new(state, @registry)
        @events = PluginEvents.new(state, @registry)
        @buffers = BufferRequests.new(state, @registry)
        @windows = WindowRequests.new(state, @registry, open_file, SplitWindow.new(open_file), OpenTab.new(open_file), close_window, file_ops)
        @files = FileRequests.new(state, file_ops)
        @ui = UiRequests.new(state, @registry, file_ops)
      end

      # Attaches the ex command runner the run_ex request uses.
      #: (ExecuteEx) -> void
      def attach(execute_ex)
        @ui.attach(execute_ex)
      end

      # ------------------------------------------------------ registration

      # Registers a plugin and gives it its own host.
      #: (PluginApi::Plugin) -> void
      def register(plugin)
        e = @registry.register(plugin)
        e.link = PluginLink.new(e.name, @registry, @buffers, @windows, @files, @ui)
        flush
      end

      # Activates every registered plugin the configuration leaves enabled.
      #: (untyped) -> void
      def activate_all(config_plugins)
        @registry.activate_all(config_plugins)
        flush
      end

      #: (Integer) -> PluginEntry
      def entry(i)
        @registry.entry(i)
      end

      #: () -> Integer
      def count
        @registry.count
      end

      #: () -> Array[String]
      def errors
        @registry.errors
      end

      #: (String) -> bool
      def enabled?(name)
        @registry.enabled?(name)
      end

      #: (String) -> String
      def reason(name)
        @registry.reason(name)
      end

      #: (String) -> String
      def describe(action)
        @registry.describe(action)
      end

      # A plugin's option value as text, "" for an unknown plugin or
      # option.
      #: (String, String) -> String
      def option(name, key)
        e = @registry.find(name)
        return "" if e.nil?
        value = e.options[key]
        value.nil? ? "" : value
      end

      # ----------------------------------------------------------- routing

      #: (String, Domain::Command) -> void
      def action(name, command)
        @router.action(name, command)
        flush
      end

      #: (String) -> bool
      def command?(name)
        @router.command?(name)
      end

      #: (Domain::ExCommand) -> Outcome
      def command(ex_command)
        outcome = @router.command(ex_command)
        flush
        outcome
      end

      #: (String, bool) -> void
      def answer(text, cancelled)
        @router.answer(text, cancelled)
        flush
      end

      # ------------------------------------------------------------ events

      # Delivers the events of the key just handled.
      #: () -> void
      def observe
        @events.observe
      end

      # A buffer was written: reported by SaveFile, since no state
      # difference tells a write from a reload, and delivered with the
      # other events of the key, after the command that wrote it, or after
      # the outermost plugin call when a plugin's request wrote it.
      #: (Domain::Buffer) -> void
      def saved(buffer)
        @events.saved(buffer)
      end

      # The editor was drawn at a size: delivers resize when it changed.
      #: (Integer, Integer) -> void
      def resized(rows, cols)
        @events.resized(rows, cols)
        flush
      end

      private

      #: () -> void
      def flush
        @events.flush
      end
    end
  end
end
