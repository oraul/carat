require_relative "../domain/editor_state"
require_relative "../domain/input_state"
require_relative "../domain/keymap"
require_relative "../domain/key"
require_relative "../domain/key_notation"
require_relative "../domain/command"
require_relative "../domain/command_grammar"
require_relative "../domain/search_prompt"
require_relative "../domain/completion_menu"
require_relative "outcome"
require_relative "concerns/reporting"
require_relative "actions/action_table"
require_relative "dispatcher"
require_relative "insert_text"
require_relative "completion/show_completion"
require_relative "edit_command_line"
require_relative "plugins/plugin_host"
require_relative "arrange_view"
require_relative "search/open_search_prompt"
require_relative "docs/follow_hover"
require_relative "docs/request_signature"
require_relative "docs/follow_signature"

module Carat
  module UseCases
    # The central use case: feeds one key through the current mode's keymap
    # and, in normal, operator-pending, and the visual modes, through the
    # command grammar, dispatching the command when it completes; in a
    # visual mode an operator completes at once and the mode stays until
    # the command ends it. Returns :handled, :pending when the keymap waits
    # for more keys until timeoutlen (keys that are bound and begin a longer
    # binding, or any prefix in insert and command-line modes), or :waiting
    # when it waits with no time limit (keys that only begin a binding, in
    # the grammar modes, as Neovim's built-in commands wait).
    # A remap sequence is queued in front of the keys still to handle, so
    # replay is a loop, not a recursion; one key may cause at most
    # MAX_REPLAYS remaps before E223 stops it. A key is looked up first in
    # the keymap of a scratch buffer the current window shows, then in the
    # mode's keymap. The grammar reads each action with the kind of its
    # handler in the action table. After every key the plugin host
    # observes the state and delivers the events the key caused.
    # ArrangeView lays out the windows again before every further key taken
    # from the queue and after the plugins observed the state, so the next
    # key sees current geometry. It owns the input state: the keys
    # the keymap waits on and the grammar. A key arriving while a message
    # of several lines shows dismisses it; Enter and Space do nothing
    # else, as at Neovim's hit-enter prompt. A search action makes the
    # grammar wait for a pattern: OpenSearchPrompt opens the command line,
    # and once a command-line action closed the prompt the text entered
    # completes the command, which is dispatched, or the command is dropped
    # when the prompt was cancelled. While the completion popup shows in
    # insert mode, a key is looked up first in the completion keymap
    # layer; a typed character and, while the popup shows, every key end
    # in ShowCompletion, which opens, filters, or closes the popup. While
    # a documentation float shows, every key ends in FollowHover, which
    # closes it when the cursor moved; with none, one comparison. A typed
    # `(` or `,` in insert mode ends in RequestSignature, and while a call
    # is followed every key ends in FollowSignature, which asks again as
    # the cursor moves through the call and closes the signature float
    # outside it; with none, one comparison.
    class HandleKey
      include Reporting

      MAX_REPLAYS = 100
      private_constant :MAX_REPLAYS

      attr_reader :keymap #: Domain::Keymap
      attr_reader :input #: Domain::InputState
      attr_reader :completion #: Domain::CompletionMenu
      attr_reader :show_completion #: ShowCompletion
      attr_reader :plugins #: PluginHost
      attr_reader :arrange_view #: ArrangeView
      attr_reader :search_prompt #: Domain::SearchPrompt
      attr_reader :open_search_prompt #: OpenSearchPrompt
      attr_reader :follow_hover #: FollowHover
      attr_reader :request_signature #: RequestSignature
      attr_reader :follow_signature #: FollowSignature
      attr_reader :signature #: Domain::SignatureRequest
      attr_reader :actions #: ActionTable
      attr_reader :dispatcher #: Dispatcher
      attr_reader :insert_text #: InsertText
      attr_reader :command_line #: EditCommandLine

      # @rbs @replays: Integer
      # @rbs @hover: Domain::HoverRequest

      #: (keymap: Domain::Keymap, input: Domain::InputState, actions: ActionTable, dispatcher: Dispatcher, insert_text: InsertText, command_line: EditCommandLine, completion: Domain::CompletionMenu, show_completion: ShowCompletion, plugins: PluginHost, arrange_view: ArrangeView, search_prompt: Domain::SearchPrompt, open_search_prompt: OpenSearchPrompt, follow_hover: FollowHover, request_signature: RequestSignature, follow_signature: FollowSignature, signature: Domain::SignatureRequest) -> void
      def initialize(keymap:, input:, actions:, dispatcher:, insert_text:, command_line:, completion:, show_completion:, plugins:, arrange_view:, search_prompt:, open_search_prompt:, follow_hover:, request_signature:, follow_signature:, signature:)
        @request_signature = request_signature
        @follow_signature = follow_signature
        @signature = signature
        @keymap = keymap
        @input = input
        @actions = actions
        @dispatcher = dispatcher
        @insert_text = insert_text
        @command_line = command_line
        @completion = completion
        @show_completion = show_completion
        @plugins = plugins
        @arrange_view = arrange_view
        @search_prompt = search_prompt
        @open_search_prompt = open_search_prompt
        @follow_hover = follow_hover
        @hover = follow_hover.hover
        @replays = 0
      end

      # Domain::Key::TIMEOUT is no key: it says the wait for more keys of
      # a binding ran out, which resolves the pending keys.
      #: (Domain::EditorState, Integer) -> Symbol
      def call(state, code)
        return timeout(state) if code == Domain::Key::TIMEOUT
        @replays = 0
        queue = [code]
        result = :handled
        until queue.empty?
          result = step(state, queue.shift, queue)
          @arrange_view.call(state) unless queue.empty?
        end
        @show_completion.call(state, false) if @completion.showing?
        @follow_hover.call(state) if @hover.float_id != 0
        @follow_signature.call(state) if @signature.active?
        @plugins.observe
        @arrange_view.call(state)
        result
      end

      private

      # Resolves pending keys after timeoutlen: the shorter binding fires if
      # there is one, otherwise the keys are dropped (or inserted as text);
      # :idle when no key was pending.
      #: (Domain::EditorState) -> Symbol
      def timeout(state)
        input = @input
        keys = input.pending_keys
        return :idle if keys.empty?
        @replays = 0
        match = lookup(state, keys)
        input.pending_keys = []
        value = match.value
        queue = []
        if value.nil?
          cancel(state)
          insert_literal(state, keys)
        else
          queue = dispatch(state, value, keys, queue)
        end
        until queue.empty?
          @arrange_view.call(state)
          step(state, queue.shift, queue)
        end
        @follow_signature.call(state) if @signature.active?
        @plugins.observe
        @arrange_view.call(state)
        :handled
      end

      # The scratch buffer's own keymap answers first; a key it neither
      # binds nor starts a binding with falls through to the mode's keymap.
      #: (Domain::EditorState, Array[Integer]) -> Domain::KeymapMatch
      def lookup(state, keys)
        local = state.buffer.keymap
        unless local.nil?
          match = local.lookup(state.mode, keys)
          return match unless match.kind == :none
        end
        @keymap.lookup(state.mode, keys)
      end

      # Whether the grammar reads keys in the current mode.
      #: (Domain::EditorState) -> bool
      def grammar_mode?(state)
        mode = state.mode
        mode == Domain::Mode::NORMAL || mode == Domain::Mode::OPERATOR_PENDING || Domain::Mode.visual?(mode)
      end

      # Handles one key; a remap it triggers is pushed to the front of queue.
      #: (Domain::EditorState, Integer, Array[Integer]) -> Symbol
      def step(state, code, queue)
        if state.list_message?
          state.clear_message
          return :handled if code == Domain::Key::CR || code == Domain::Key::SPACE
        end
        state.clear_message
        input = @input
        return complete(state, code, queue) if @completion.showing? && state.mode == Domain::Mode::INSERT && input.pending_keys.empty? && completion_key?(code)
        if grammar_mode?(state)
          grammar = input.grammar
          if grammar.wants_char?
            finish(state, grammar.char(code))
            return :handled
          end
          if input.pending_keys.empty? && grammar.digit?(code)
            grammar.digit(code)
            return :handled
          end
        end
        input.pending_keys << code
        match = lookup(state, input.pending_keys)
        case match.kind
        when :match
          keys = input.take_keys
          dispatch(state, match.value, keys, queue)
          :handled
        when :prefix
          grammar_mode?(state) ? :waiting : :pending
        when :match_prefix
          :pending
        else
          keys = input.take_keys
          cancel(state)
          insert_literal(state, keys)
          :handled
        end
      end

      # Whether the key is bound in the completion layer, which answers
      # first while the popup shows; only single keys bind there.
      #: (Integer) -> bool
      def completion_key?(code)
        @keymap.lookup(Domain::Mode::COMPLETION, [code]).kind == :match
      end

      # Runs the completion layer's binding of the key.
      #: (Domain::EditorState, Integer, Array[Integer]) -> Symbol
      def complete(state, code, queue)
        keys = [code]
        dispatch(state, @keymap.lookup(Domain::Mode::COMPLETION, keys).value, keys, queue)
        :handled
      end

      # Runs the binding's value: an action through the grammar or the
      # dispatcher, a key sequence by putting its keys at the front of the
      # queue. Returns the queue, which the caller assigns: on the pinned
      # Spinel the appends to an array the caller created as [] are lost
      # (docs/spinel-notes.md), as the timeout's queue is.
      #: (Domain::EditorState, String?, Array[Integer], Array[Integer]) -> Array[Integer]
      def dispatch(state, value, keys, queue)
        return queue if value.nil?
        return replay(state, value, queue) unless Domain::Keymap.action_name?(value)
        if Domain::Mode.visual?(state.mode)
          finish(state, @input.grammar.accept_visual(value, @actions.kind_of(value), keys))
        elsif grammar_mode?(state)
          finish(state, @input.grammar.accept(value, @actions.kind_of(value), keys))
        else
          @dispatcher.call(state, Domain::Command.plain(value))
          resume(state) if state.mode != Domain::Mode::CMDLINE && @input.grammar.wants_pattern?
        end
        queue
      end

      # The search prompt has closed: the text entered finishes the
      # waiting search command, which is dispatched in the mode the prompt
      # returned to; a cancelled prompt drops the command.
      #: (Domain::EditorState) -> void
      def resume(state)
        grammar = @input.grammar
        prompt = @search_prompt
        unless prompt.entered
          grammar.reset
          return
        end
        command = grammar.pattern(prompt.take_text)
        state.mode = Domain::Mode::NORMAL unless Domain::Mode.visual?(state.mode)
        @dispatcher.call(state, command)
      end

      # Acts on what the grammar said: an operator switches to
      # operator-pending mode, a search opens its prompt, a complete
      # command returns to normal mode
      # and is dispatched (the command itself may enter insert mode), a
      # cancel returns to normal mode, and pending waits. In a visual mode
      # the mode stays: the dispatched command decides what comes next.
      #: (Domain::EditorState, Symbol) -> void
      def finish(state, result)
        visual = Domain::Mode.visual?(state.mode)
        case result
        when :operator
          state.mode = Domain::Mode::OPERATOR_PENDING
        when :prompt
          @open_search_prompt.call(state, @input.grammar.action)
        when :complete
          state.mode = Domain::Mode::NORMAL unless visual
          @dispatcher.call(state, @input.grammar.take)
        when :cancel
          state.mode = Domain::Mode::NORMAL unless visual
        end
      end

      # An unbound key drops whatever command was being typed; a visual
      # mode stays.
      #: (Domain::EditorState) -> void
      def cancel(state)
        return unless grammar_mode?(state)
        @input.grammar.reset
        state.mode = Domain::Mode::NORMAL unless Domain::Mode.visual?(state.mode)
      end

      # Puts the sequence's keys at the front of the queue and returns it.
      #: (Domain::EditorState, String, Array[Integer]) -> Array[Integer]
      def replay(state, sequence, queue)
        @replays += 1
        if @replays > MAX_REPLAYS
          report(state, Outcome.failure("E223: Recursive mapping"))
          queue.clear
          return queue
        end
        parsed = Domain::KeyNotation.parse(sequence, "")
        unless parsed.ok?
          report(state, Outcome.failure("Bad mapping: #{sequence}"))
          return queue
        end
        codes = parsed.codes
        i = codes.length - 1
        while i >= 0
          queue.unshift(codes[i])
          i -= 1
        end
        queue
      end

      #: (Domain::EditorState, Array[Integer]) -> void
      def insert_literal(state, keys)
        mode = state.mode
        return unless mode == Domain::Mode::INSERT || mode == Domain::Mode::CMDLINE
        i = 0
        while i < keys.length
          code = keys[i]
          if Domain::Key.printable?(code)
            text = Domain::Key.char(code)
            if mode == Domain::Mode::INSERT
              report(state, @insert_text.call(state, text))
              @show_completion.call(state, true)
              @request_signature.call(state) if code == 40 || code == 44
            else
              @command_line.call(state, text)
            end
          end
          i += 1
        end
      end
    end
  end
end
