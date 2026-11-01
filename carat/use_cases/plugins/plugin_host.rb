require_relative "../../plugin_api"
require_relative "../../domain/editor_state"
require_relative "../../domain/buffer_list"
require_relative "../../domain/tab_list"
require_relative "../../domain/input_state"
require_relative "../../domain/plugin_ui"
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
require_relative "../ex/command_runner"
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
    # no plugin call is in progress any more. The ex command runner is
    # given already built: the plugin command handler, which routes
    # plugin commands here, is registered in its table after the host is
    # made, so nothing is attached later.
    class PluginHost
      attr_reader :state #: Domain::EditorState
      attr_reader :plugin_ui #: Domain::PluginUi
      attr_reader :registry #: PluginRegistry
      attr_reader :events #: PluginEvents
      attr_reader :file_ops #: FileOps
      attr_reader :buffer_requests #: BufferRequests
      attr_reader :window_requests #: WindowRequests
      attr_reader :file_requests #: FileRequests
      attr_reader :ui_requests #: UiRequests

      # @rbs @router: PluginRouter

      # The records, the window use cases, and the runner are the editor's
      # own, built once by the assembly; the registry, the router, the
      # events, the file operations, and the request families are the
      # host's parts and built here from them.
      #: (state: Domain::EditorState, buffers: Domain::BufferList, tabs: Domain::TabList, input: Domain::InputState, plugin_ui: Domain::PluginUi, files: Ports::FilePort, open_file: OpenFile, close_window: CloseWindow, split_window: SplitWindow, open_tab: OpenTab, keymap: Domain::Keymap, leader: String, runner: CommandRunner) -> void
      def initialize(state:, buffers:, tabs:, input:, plugin_ui:, files:, open_file:, close_window:, split_window:, open_tab:, keymap:, leader:, runner:)
        @state = state
        @plugin_ui = plugin_ui
        @file_ops = FileOps.new(files: files, buffers: buffers)
        @registry = PluginRegistry.new(state: state, buffers: buffers, tabs: tabs, plugin_ui: plugin_ui, keymap: keymap, leader: leader, close_window: close_window)
        @router = PluginRouter.new(state: state, registry: @registry, plugin_ui: plugin_ui)
        @events = PluginEvents.new(state: state, buffers: buffers, tabs: tabs, registry: @registry)
        @buffer_requests = BufferRequests.new(state: state, buffers: buffers, registry: @registry)
        @window_requests = WindowRequests.new(state: state, buffers: buffers, tabs: tabs, registry: @registry, open_file: open_file, split_window: split_window, open_tab: open_tab, close_window: close_window, file_ops: @file_ops)
        @file_requests = FileRequests.new(file_ops: @file_ops)
        @ui_requests = UiRequests.new(state: state, registry: @registry, file_ops: @file_ops, plugin_ui: plugin_ui, input: input, runner: runner)
      end

      # ------------------------------------------------------ registration

      # Registers a plugin and gives it its own host.
      #: (PluginApi::Plugin) -> void
      def register(plugin)
        e = @registry.register(plugin)
        e.link = PluginLink.new(name: e.name, registry: @registry, buffer_requests: @buffer_requests, window_requests: @window_requests, file_requests: @file_requests, ui_requests: @ui_requests)
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

      # Runs a plugin action and delivers what it caused; returns the
      # router's outcome, a failure when no enabled plugin declares it.
      #: (String, Domain::Command) -> Outcome
      def action(name, command)
        outcome = @router.action(name, command)
        flush
        outcome
      end

      # Every action name a registered plugin declares, enabled or not, so
      # a configuration binding of a disabled plugin's action is not
      # reported as unknown.
      #: () -> Array[String]
      def action_names
        @registry.action_names
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
