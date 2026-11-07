require_relative "../ports/language_service_port"
require_relative "../ports/clock_port"
require_relative "../domain/completion_request"
require_relative "../domain/hover_request"
require_relative "../domain/markdown_text"
require_relative "../domain/completion_list"
require_relative "../domain/completion_item"
require_relative "../domain/mode"
require_relative "../domain/fuzzy_match"

module Carat
  module Adapters
    # The language server client: speaks JSON-RPC to one server per
    # language through the process port and reads what the servers' reader
    # threads queued, only when the editor is idle (InputController's tick),
    # so a key never waits on a server or pays for one. A server starts for
    # the current buffer's file type when language.<type>.lsp names a
    # command and the working directory is under a trusted root (trusted?),
    # since a server such as ruby-lsp runs the project's own code; in any
    # other directory the lsp slot reads untrusted until :LspStart. Once a
    # server answered initialize it is told about each buffer of its file
    # type with a path: didOpen, didChange with the whole text when
    # the buffer's change counters moved, didSave after SaveFile wrote it,
    # and didClose when the buffer is gone. Its output is untrusted: a body
    # that is not a JSON object is dropped, at most DRAIN_LIMIT messages are
    # read per tick, and the name and every diagnostic message are stripped
    # of control characters and capped (Domain::ControlText). A publish is
    # handed at the next idle tick to the buffers of its file, which draw
    # it as signs and the cursor line's message, and the current buffer's
    # counts go to the bar's diagnostics slot. A server whose initialize
    # failed is stopped as crashed. The completion source's wanted word
    # (Domain::CompletionRequest) is sent as textDocument/completion once
    # no other word was wanted for DEBOUNCE seconds, after the document
    # sync; a request for a word no longer wanted, or unanswered
    # ANSWER_LIMIT seconds past its deadline, is cancelled, and an answer
    # to no request in flight is dropped. An answer is bounded and cleaned
    # (at most CompletionList::LIMIT items through
    # CompletionItem.from_source) and marked arrived for the popup; the
    # server's items are kept beside it, and so is each item's
    # documentation (Domain::CompletionDocs), cut to DOCUMENT_LIMIT bytes,
    # untrusted. The candidate the popup picks is sent as
    # completionItem/resolve once no other was picked for SETTLE seconds,
    # when its server advertised resolveProvider and its documentation was
    # neither in the answer nor asked for: one request per candidate of an
    # answer, one in flight, cancelled when unanswered ANSWER_LIMIT
    # seconds past its deadline or when a new answer comes; only the
    # answer to the request in flight is read, and its documentation is
    # marked arrived for the float. The hover ask K records
    # (Domain::HoverRequest) is sent as textDocument/hover at the next
    # idle tick when the cursor is still where K was typed and the
    # server advertised hoverProvider, one request in flight, cancelled by
    # a newer ask or when unanswered ANSWER_LIMIT seconds after it was
    # sent; only the answer to it is read, its contents joined into one
    # markdown text of at most PART_LIMIT parts and
    # MarkdownText::RAW_LIMIT bytes, untrusted, and marked arrived.
    class JsonRpcLanguageGateway < Ports::LanguageServicePort
      DRAIN_LIMIT = 64
      NAME_LIMIT = 32
      MESSAGE_LIMIT = 500
      DIAGNOSTIC_LIMIT = 1000
      METHOD_NOT_FOUND = -32_601
      FILE_SCHEME = "file:"
      # Server requests answered with a null result; any other gets
      # METHOD_NOT_FOUND.
      NULL_REQUESTS = ["window/workDoneProgress/create", "client/registerCapability", "client/unregisterCapability"]
      DEBOUNCE = 0.1
      ANSWER_LIMIT = 2.0
      SETTLE = 0.1
      DOCUMENT_LIMIT = 16_384
      PART_LIMIT = 16
      # The menu kind of each LSP CompletionItemKind, by number: interface,
      # enum, and struct read as class; value and enum member as constant.
      KIND_NAMES = ["text", "text", "method", "function", "constructor", "field", "variable", "class", "class", "module", "property", "text", "constant", "class", "keyword", "snippet", "text", "text", "text", "text", "constant", "constant", "class", "text", "text", "text"]

      # @rbs @servers: Array[untyped]
      # @rbs @refused: Array[String]
      # @rbs @saves: Array[Integer]
      # @rbs @trust: Symbol
      # @rbs @published: Array[String]
      # @rbs @items: Array[untyped]
      # @rbs @resolvers: Array[String]

      attr_reader :processes #: Ports::ProcessPort
      attr_reader :messages #: Ports::MessageQueuePort
      attr_reader :files #: Ports::FilePort
      attr_reader :buffers #: Domain::BufferList
      attr_reader :config #: Domain::Config
      attr_reader :slots #: Domain::StatusSlots
      attr_reader :completion #: Domain::CompletionRequest
      attr_reader :clock #: Ports::ClockPort
      attr_reader :hover #: Domain::HoverRequest

      #: (processes: Ports::ProcessPort, messages: Ports::MessageQueuePort, files: Ports::FilePort, buffers: Domain::BufferList, config: Domain::Config, slots: Domain::StatusSlots, completion: Domain::CompletionRequest, clock: Ports::ClockPort, hover: Domain::HoverRequest) -> void
      def initialize(processes:, messages:, files:, buffers:, config:, slots:, completion:, clock:, hover:)
        @hover = hover
        @processes = processes
        @messages = messages
        @files = files
        @buffers = buffers
        @config = config
        @slots = slots
        @completion = completion
        @clock = clock
        @servers = []
        @refused = []
        @saves = []
        @trust = :unknown
        @published = []
        @items = []
        @resolvers = [""]
        @resolvers.clear
      end

      # @rbs state: Domain::EditorState
      def poll(state)
        changed = drain
        apply(state.options.icons)
        changed = @slots.count_diagnostics(state.buffer.diagnostics) || changed
        language = state.buffer.filetype
        current = server_for(language)
        held = false
        if current.nil? && command?(language) && !@refused.include?(language)
          if trusted?
            current = launch(language)
          else
            held = true
          end
        end
        i = 0
        while i < @servers.length
          server = server_at(i)
          sync(server) if server.running?
          i += 1
        end
        @saves.clear
        complete(state)
        resolve
        send_hover(state)
        return hold(language) || changed if held
        show(current) || changed
      end

      # Starts the current buffer's server when none runs for its
      # language, in any directory: the explicit start an untrusted
      # directory waits for. A server that crashed or was stopped (handle
      # 0) runs no more: its entry is dropped and a new one launched.
      # Answers the message to show, "" when a server starts or already
      # runs.
      # @rbs state: Domain::EditorState
      def start(state)
        language = state.buffer.filetype
        unless command?(language)
          show(nil)
          return "No language server for this buffer"
        end
        server = server_for(language)
        if !server.nil? && server.handle == 0
          forget(language)
          clear_shown(language)
          server = nil
        end
        if server.nil?
          @refused.delete(language)
          server = launch(language)
        end
        show(server)
        server.nil? ? "Cannot start #{words_of(language).join(" ")}" : ""
      end

      # Answers whether a wanted completion, a picked candidate's
      # documentation, or a hover ask is not yet sent or a request is in
      # flight.
      # @rbs skip
      def waiting?
        @completion.waiting? || @completion.docs.waiting? || @hover.waiting?
      end

      #: (Domain::Buffer) -> void
      def saved(buffer)
        @saves << buffer.id unless @saves.include?(buffer.id)
      end

      # @rbs state: Domain::EditorState
      def restart(state)
        stop
        i = 0
        while i < @servers.length
          clear_shown(server_at(i).language)
          i += 1
        end
        @servers.clear
        @refused.clear
        language = state.buffer.filetype
        unless command?(language)
          show(nil)
          return "No language server for this buffer"
        end
        server = launch(language)
        show(server)
        server.nil? ? "Cannot start #{words_of(language).join(" ")}" : ""
      end

      #: () -> void
      def stop
        i = 0
        while i < @servers.length
          server = server_at(i)
          i += 1
          next if server.handle == 0
          forget_completion(server)
          forget_hover(server)
          request(server, "shutdown", nil)
          notify(server, "exit", nil)
          @processes.stop(server.handle)
          server.handle = 0
          server.state = :stopped
        end
        show(@servers.empty? ? nil : server_at(0))
      end

      # The diagnostics a server published for a path, in its order.
      #: (String) -> Domain::DiagnosticList
      def diagnostics(path)
        listed(uri_of(path))
      end

      # The diagnostics a server published for a URI, an empty list for
      # none.
      #: (String) -> Domain::DiagnosticList
      def listed(uri)
        i = 0
        while i < @servers.length
          list = server_at(i).diagnostics[uri]
          return list unless list.nil?
          i += 1
        end
        Domain::DiagnosticList.new
      end

      # The server of a language, or nil.
      #: (String) -> Domain::LanguageServer?
      def server_for(language)
        i = 0
        while i < @servers.length
          return server_at(i) if server_at(i).language == language
          i += 1
        end
        nil
      end

      private

      # Drops a language's server entry, which runs no more.
      #: (String) -> void
      def forget(language)
        i = 0
        while i < @servers.length
          if server_at(i).language == language
            @servers.delete_at(i)
            return
          end
          i += 1
        end
      end

      # The server at an index, typed: the list is Array[untyped].
      #: (Integer) -> Domain::LanguageServer
      def server_at(index)
        @servers[index]
      end

      #: (String) -> bool
      def command?(language)
        !language.empty? && !words_of(language).empty?
      end

      #: (String) -> Array[String]
      def words_of(language)
        line = @config.last("language.#{language}.lsp")
        line.nil? ? [] : line.words
      end

      # Whether servers may start on their own in the working directory:
      # it is, or is under, a root of language.trusted_roots, which only
      # the defaults and the user file set. A root is an absolute path or
      # ~/ under the home directory; any other word is no root. The answer
      # is kept, since neither the directory nor the configuration changes.
      #: () -> bool
      def trusted?
        @trust = trust_of(@files.cwd) if @trust == :unknown
        @trust == :trusted
      end

      #: (String) -> Symbol
      def trust_of(cwd)
        line = @config.last(Domain::Config::TRUSTED_ROOTS)
        return :untrusted if line.nil? || !cwd.start_with?("/")
        words = line.words
        i = 0
        while i < words.length
          root = root_of(words[i].to_s)
          i += 1
          next if root.empty?
          return :trusted if root == "/" || cwd == root || cwd.start_with?("#{root}/")
        end
        :untrusted
      end

      # A root word as an absolute path without a trailing slash, "" when
      # it is not absolute, names no home, or holds a . or .. segment.
      #: (String) -> String
      def root_of(word)
        path = word
        if word == "~" || word.start_with?("~/")
          home = @files.home
          return "" if home.empty?
          path = "#{home}#{word[1, word.length - 1]}"
        end
        return "" unless path.start_with?("/")
        return "" if "#{path}/".include?("/./") || "#{path}/".include?("/../")
        while path.length > 1 && path.end_with?("/")
          path = path[0, path.length - 1].to_s
        end
        path
      end

      # Shows a language's server as waiting for an explicit start in an
      # untrusted directory; answers whether the slot changed.
      #: (String) -> bool
      def hold(language)
        name = Domain::ControlText.strip(File.basename(words_of(language)[0].to_s), NAME_LIMIT)
        @slots.set_lsp(name, :untrusted, 0)
      end

      # Starts a language's server and sends initialize; nil when the
      # command cannot start, remembered until a restart.
      #: (String) -> Domain::LanguageServer?
      def launch(language)
        words = words_of(language)
        handle = @processes.spawn(words)
        if handle == 0
          @refused << language
          return nil
        end
        name = Domain::ControlText.strip(File.basename(words[0]), NAME_LIMIT)
        server = Domain::LanguageServer.new(language: language, words: words, name: name, handle: handle)
        @servers << server
        server.init_id = request(server, "initialize", initialize_params)
        server
      end

      #: () -> Hash[String, untyped]
      def initialize_params
        root = uri_of(@files.cwd)
        sync = { "didSave" => true, "dynamicRegistration" => false }
        item = { "snippetSupport" => false, "documentationFormat" => ["markdown", "plaintext"], "resolveSupport" => { "properties" => ["documentation"] } }
        completion = { "completionItem" => item, "contextSupport" => true }
        hover = { "contentFormat" => ["markdown", "plaintext"], "dynamicRegistration" => false }
        document = { "synchronization" => sync, "publishDiagnostics" => { "relatedInformation" => false }, "completion" => completion, "hover" => hover }
        capabilities = { "textDocument" => document, "window" => { "workDoneProgress" => true } }
        { "processId" => nil, "clientInfo" => { "name" => "carat" }, "rootUri" => root, "capabilities" => capabilities, "workspaceFolders" => [{ "uri" => root, "name" => File.basename(@files.cwd) }] }
      end

      # Shows a server on the bar, or empties the slot for nil; answers
      # whether the slot changed.
      #: (Domain::LanguageServer?) -> bool
      def show(server)
        return @slots.set_lsp("", :none, 0) if server.nil?
        @slots.set_lsp(server.name, server.state, server.percent)
      end

      # Handles at most DRAIN_LIMIT queued messages; answers whether any.
      #: () -> bool
      def drain
        count = 0
        while count < DRAIN_LIMIT
          message = @messages.pop
          break if message.nil?
          handle(message)
          count += 1
        end
        count > 0
      end

      #: (Domain::ServiceMessage) -> void
      def handle(message)
        server = by_handle(message.handle)
        return if server.nil?
        if message.body?
          receive(server, message.text)
        else
          crash(server)
        end
      end

      #: (Integer) -> Domain::LanguageServer?
      def by_handle(handle)
        return nil if handle == 0
        i = 0
        while i < @servers.length
          return server_at(i) if server_at(i).handle == handle
          i += 1
        end
        nil
      end

      # The server ended without being stopped, or its output broke a
      # limit: its process is stopped and the bar names the restart.
      #: (Domain::LanguageServer) -> void
      def crash(server)
        forget_completion(server)
        forget_hover(server)
        @processes.stop(server.handle)
        server.handle = 0
        server.state = :crashed
        server.tasks = 0
      end

      #: (Domain::LanguageServer, String) -> void
      def receive(server, text)
        value = parse(text)
        return unless value.is_a?(Hash)
        name = value["method"]
        if name.is_a?(String)
          if value.key?("id")
            answer(server, name.to_s, value["id"])
          else
            notified(server, name.to_s, value["params"])
          end
        elsif value["id"] == server.init_id && server.state == :starting
          result = value["result"]
          if value.key?("error") || !result.is_a?(Hash)
            crash(server)
          else
            initialized(server, result)
          end
        elsif @completion.sent_id != 0 && value["id"] == @completion.sent_id && server.language == @completion.language
          completed(value.key?("error") ? nil : value["result"])
        elsif @completion.docs.sent_id != 0 && value["id"] == @completion.docs.sent_id && server.language == @completion.language
          resolved(value.key?("error") ? nil : value["result"])
        elsif @hover.sent_id != 0 && value["id"] == @hover.sent_id && server.language == @hover.language
          hovered(value.key?("error") ? nil : value["result"])
        end
      end

      # The JSON value of a body, or nil when it is not JSON.
      #: (String) -> untyped
      def parse(text)
        Json.parse(text)
      rescue Json::Error
        nil
      end

      # The initialize result: the server's name, ready, and initialized.
      #: (Domain::LanguageServer, untyped) -> void
      def initialized(server, result)
        info = result.is_a?(Hash) ? result["serverInfo"] : nil
        name = info.is_a?(Hash) ? info["name"] : nil
        if name.is_a?(String)
          stripped = Domain::ControlText.strip(name.to_s, NAME_LIMIT)
          server.name = stripped unless stripped.empty?
        end
        caps = result.is_a?(Hash) ? result["capabilities"] : nil
        provider = caps.is_a?(Hash) ? caps["completionProvider"] : nil
        @completion.languages << server.language if provider.is_a?(Hash) && !@completion.completes?(server.language)
        @resolvers << server.language if provider.is_a?(Hash) && provider["resolveProvider"] == true && !@resolvers.include?(server.language)
        hovers = caps.is_a?(Hash) ? caps["hoverProvider"] : nil
        @hover.languages << server.language if (hovers == true || hovers.is_a?(Hash)) && !@hover.hovers?(server.language)
        server.state = :ready
        notify(server, "initialized", {})
      end

      # A server that runs no more completes no more, and its request in
      # flight is forgotten.
      #: (Domain::LanguageServer) -> void
      def forget_completion(server)
        ask = @completion
        ask.languages.delete(server.language)
        @resolvers.delete(server.language)
        return unless ask.language == server.language
        ask.sent_id = 0
        ask.docs.sent_id = 0
      end

      # Sends the wanted word's completion request once no other word was
      # wanted for DEBOUNCE seconds, when the current buffer, row, and mode
      # still hold the word, the cursor ends a word of at least one byte
      # that starts at the wanted column, and its server completes; a newer want cancels
      # the request in flight, and so does an answer overdue.
      #: (Domain::EditorState) -> void
      def complete(state)
        ask = @completion
        return unless ask.waiting?
        now = @clock.now
        if ask.want != ask.seen
          ask.seen = ask.want
          ask.due = now + DEBOUNCE
          cancel
          return
        end
        if ask.sent_id != 0
          cancel if now > ask.due + ANSWER_LIMIT
          return
        end
        return if now < ask.due
        ask.sent = ask.want
        buffer = state.buffer
        cursor = state.cursor
        return unless state.mode == Domain::Mode::INSERT && buffer.id == ask.buffer_id && cursor.row == ask.row && cursor.col > ask.col
        line = buffer.line(cursor.row)[0, cursor.col].to_s
        start = Domain::FuzzyMatch.word_start(line)
        typed = line.byteslice(start, line.bytesize - start).to_s
        return if typed.empty? || cursor.col - typed.length != ask.col
        server = server_for(buffer.filetype)
        return if server.nil? || !server.running? || !ask.completes?(server.language) || buffer.path.empty?
        position = { "line" => cursor.row, "character" => utf16_length(line) }
        params = { "textDocument" => { "uri" => uri_of(buffer.path) }, "position" => position, "context" => { "triggerKind" => 1 } }
        ask.word = typed
        ask.language = server.language
        ask.sent_id = request(server, "textDocument/completion", params)
      end

      # Cancels the completion request in flight, whose answer is then
      # dropped.
      #: () -> void
      def cancel
        ask = @completion
        return if ask.sent_id == 0
        server = server_for(ask.language)
        notify(server, "$/cancelRequest", { "id" => ask.sent_id }) unless server.nil?
        ask.sent_id = 0
      end

      # Keeps a completion answer for the word it was sent for: at most
      # CompletionList::LIMIT items with a string label, each cleaned and
      # bounded, the server's item and its documentation beside each; an
      # error or another value is an empty answer. The resolve request in
      # flight is for the answer replaced, so it is cancelled.
      #: (untyped) -> void
      def completed(result)
        ask = @completion
        docs = ask.docs
        cancel_resolve
        docs.clear
        @items.clear
        resolves = @resolvers.include?(ask.language)
        items = result.is_a?(Hash) ? result["items"] : result
        list = Domain::CompletionList.new
        if items.is_a?(Array)
          items.each do |item|
            break if list.count >= Domain::CompletionList::LIMIT
            candidate = candidate_of(item)
            next if candidate.nil?
            list.add(candidate)
            @items << item
            text = document_of(item)
            docs.add(text, text.empty? && resolves ? Domain::CompletionDocs::TO_RESOLVE : Domain::CompletionDocs::HELD)
          end
        end
        ask.list = list
        ask.answered = ask.sent
        ask.sent_id = 0
        ask.arrived = true
      end

      # Sends the picked candidate's completionItem/resolve once no other
      # was picked for SETTLE seconds, when its documentation is still to
      # resolve, no resolve is in flight, and the answer's server runs and
      # resolves; the candidate is then asked, never sent again for this
      # answer. A request unanswered ANSWER_LIMIT seconds past its
      # deadline is cancelled; a new pick waits for the one in flight.
      #: () -> void
      def resolve
        docs = @completion.docs
        return unless docs.waiting?
        now = @clock.now
        if docs.want != docs.seen
          docs.seen = docs.want
          docs.due = now + SETTLE
          return
        end
        if docs.sent_id != 0
          cancel_resolve if now > docs.due + ANSWER_LIMIT
          return
        end
        return if now < docs.due
        docs.sent = docs.want
        index = docs.index
        return unless docs.to_resolve?(index) && index < @items.length
        server = server_for(@completion.language)
        return if server.nil? || !server.running? || !@resolvers.include?(server.language)
        docs.known[index] = Domain::CompletionDocs::ASKED
        docs.sent_index = index
        docs.sent_id = request(server, "completionItem/resolve", @items[index])
      end

      # Cancels the resolve request in flight, whose answer is then dropped.
      #: () -> void
      def cancel_resolve
        docs = @completion.docs
        return if docs.sent_id == 0
        server = server_for(@completion.language)
        notify(server, "$/cancelRequest", { "id" => docs.sent_id }) unless server.nil?
        docs.sent_id = 0
      end

      # Keeps the documentation of a resolve answer for the candidate it was
      # sent for, marked arrived when there is any; an error or another
      # value holds none.
      #: (untyped) -> void
      def resolved(result)
        docs = @completion.docs
        index = docs.sent_index
        docs.sent_id = 0
        return if index < 0 || index >= docs.texts.length
        text = document_of(result)
        docs.texts[index] = text
        docs.known[index] = Domain::CompletionDocs::HELD
        docs.arrived = true unless text.empty?
      end

      # A server that runs no more hovers no more, and its request in
      # flight is forgotten.
      #: (Domain::LanguageServer) -> void
      def forget_hover(server)
        ask = @hover
        ask.languages.delete(server.language)
        ask.sent_id = 0 if ask.language == server.language
      end

      # Sends the latest hover ask once, when the layout window, its
      # buffer, the cursor, and normal mode are still where K was typed
      # and the buffer's server hovers; a newer ask cancels the request in
      # flight, and so does an answer overdue.
      #: (Domain::EditorState) -> void
      def send_hover(state)
        ask = @hover
        return unless ask.waiting?
        if ask.sent_id != 0
          if ask.sent == ask.want
            cancel_hover if @clock.now > ask.deadline
            return
          end
          cancel_hover
        end
        return if ask.sent == ask.want
        ask.sent = ask.want
        window = state.tab.layout_window
        buffer = window.buffer
        cursor = window.cursor
        return unless state.mode == Domain::Mode::NORMAL && ask.at?(window.id, buffer.id, cursor.row, cursor.col)
        server = server_for(buffer.filetype)
        return if server.nil? || !server.running? || !ask.hovers?(server.language) || buffer.path.empty?
        line = buffer.line(cursor.row)[0, cursor.col].to_s
        params = { "textDocument" => { "uri" => uri_of(buffer.path) }, "position" => { "line" => cursor.row, "character" => utf16_length(line) } }
        ask.language = server.language
        ask.deadline = @clock.now + ANSWER_LIMIT
        ask.sent_id = request(server, "textDocument/hover", params)
      end

      # Cancels the hover request in flight, whose answer is then dropped.
      #: () -> void
      def cancel_hover
        ask = @hover
        return if ask.sent_id == 0
        server = server_for(ask.language)
        notify(server, "$/cancelRequest", { "id" => ask.sent_id }) unless server.nil?
        ask.sent_id = 0
      end

      # Keeps the hover answer's contents as one markdown text, "" for an
      # error or none, marked arrived.
      #: (untyped) -> void
      def hovered(result)
        ask = @hover
        ask.sent_id = 0
        ask.text = hover_text(result.is_a?(Hash) ? result["contents"] : nil)
        ask.arrived = true
      end

      # The markdown of hover contents: a markup content, a marked string,
      # or a list of at most PART_LIMIT marked strings joined by blank
      # lines, cut to MarkdownText::RAW_LIMIT bytes as it grows.
      #: (untyped) -> String
      def hover_text(contents)
        limit = Domain::MarkdownText::RAW_LIMIT
        return markdown_of(contents, limit) unless contents.is_a?(Array)
        out = +""
        count = contents.length
        count = PART_LIMIT if count > PART_LIMIT
        i = 0
        while i < count && out.bytesize < limit
          piece = markdown_of(contents[i], limit - out.bytesize)
          i += 1
          next if piece.strip.empty?
          out << "\n\n" unless out.empty?
          out << piece
        end
        out.bytesize > limit ? out.byteslice(0, limit).to_s : out
      end

      # One part's markdown, at most limit bytes: a string, a markup
      # content's value, or a language and value pair as a fenced block
      # whose language is stripped of controls; "" for anything else.
      #: (untyped, Integer) -> String
      def markdown_of(part, limit)
        text = ""
        if part.is_a?(String)
          text = part.to_s
        elsif part.is_a?(Hash) && part["value"].is_a?(String)
          text = part["value"].to_s
          language = part["language"]
          text = "```" + Domain::ControlText.strip(language.to_s, NAME_LIMIT) + "\n" + text + "\n```" if language.is_a?(String)
        end
        return text if text.bytesize <= limit
        text.byteslice(0, limit).to_s
      end

      # The documentation of a server's item: a string or a markup
      # content's value, cut to DOCUMENT_LIMIT bytes; "" for none.
      #: (untyped) -> String
      def document_of(item)
        return "" unless item.is_a?(Hash)
        value = item["documentation"]
        value = value["value"] if value.is_a?(Hash)
        return "" unless value.is_a?(String)
        text = value.to_s
        text.bytesize > DOCUMENT_LIMIT ? text.byteslice(0, DOCUMENT_LIMIT).to_s : text
      end

      # A completion item as a candidate, nil without a string label.
      #: (untyped) -> Domain::CompletionItem?
      def candidate_of(item)
        return nil unless item.is_a?(Hash)
        label = item["label"]
        return nil unless label.is_a?(String)
        number = item["kind"]
        kind = number.is_a?(Integer) && number.to_i > 0 && number.to_i < KIND_NAMES.length ? KIND_NAMES[number.to_i].to_s : "text"
        detail = item["detail"]
        edit = item["textEdit"]
        text = edit.is_a?(Hash) ? edit["newText"] : nil
        text = item["insertText"] unless text.is_a?(String)
        Domain::CompletionItem.from_source(label.to_s, kind, detail.is_a?(String) ? detail.to_s : "", text.is_a?(String) ? text.to_s : "")
      end

      # The UTF-16 code units of a text: one per character, two for one
      # outside the basic plane (a four-byte UTF-8 sequence).
      #: (String) -> Integer
      def utf16_length(text)
        count = 0
        i = 0
        while i < text.bytesize
          b = text.getbyte(i).to_i
          count += 1 if (b & 0xC0) != 0x80
          count += 1 if b >= 0xF0
          i += 1
        end
        count
      end

      # Answers a server's request, so a server waiting on it goes on.
      #: (Domain::LanguageServer, String, untyped) -> void
      def answer(server, name, id)
        return unless id.is_a?(Integer) || id.is_a?(String)
        if NULL_REQUESTS.include?(name)
          deliver(server, { "jsonrpc" => "2.0", "id" => id, "result" => nil })
        else
          deliver(server, { "jsonrpc" => "2.0", "id" => id, "error" => { "code" => METHOD_NOT_FOUND, "message" => "not supported" } })
        end
      end

      #: (Domain::LanguageServer, String, untyped) -> void
      def notified(server, name, params)
        return unless params.is_a?(Hash)
        if name == "$/progress"
          progress(server, params["value"])
        elsif name == "textDocument/publishDiagnostics"
          published(server, params["uri"], params["diagnostics"])
        end
      end

      # A work-done progress report: begin and end count the reports that
      # run, and the percent is the last one given.
      #: (Domain::LanguageServer, untyped) -> void
      def progress(server, value)
        return unless value.is_a?(Hash) && server.running?
        kind = value["kind"]
        percent = value["percentage"]
        if kind == "begin"
          server.tasks = server.tasks + 1
          server.percent = 0
        elsif kind == "end"
          server.tasks = server.tasks - 1 if server.tasks > 0
        end
        server.percent = bounded(percent.to_i, 0, 100) if percent.is_a?(Integer) || percent.is_a?(Float)
        server.state = server.tasks > 0 ? :indexing : :ready
      end

      # Keeps a file's diagnostics as values, replacing its earlier ones.
      #: (Domain::LanguageServer, untyped, untyped) -> void
      def published(server, uri, list)
        return unless uri.is_a?(String) && list.is_a?(Array)
        values = Domain::DiagnosticList.new
        list.each do |item|
          break if values.count >= DIAGNOSTIC_LIMIT
          diagnostic = diagnostic_of(item)
          values.add(diagnostic) unless diagnostic.nil?
        end
        server.diagnostics[uri.to_s] = values
        @published << uri.to_s unless @published.include?(uri.to_s)
      end

      # Hands each file published since the last tick to the buffers whose
      # path makes its URI, the signs in the icon set's glyphs.
      #: (String) -> void
      def apply(set)
        return if @published.empty?
        glyphs = [Domain::Icons.glyph("error", set), Domain::Icons.glyph("warning", set), Domain::Icons.glyph("info", set), Domain::Icons.glyph("hint", set)]
        i = 0
        while i < @buffers.count
          buffer = @buffers.buffer_at(i)
          i += 1
          path = buffer.path_text
          next if path.empty?
          uri = uri_of(path)
          next unless @published.include?(uri)
          list = listed(uri)
          if list.empty?
            buffer.clear_diagnostics
          else
            buffer.set_diagnostics(list, glyphs)
          end
        end
        @published.clear
        nil
      end

      # Removes the drawn diagnostics of a file type's buffers, whose server
      # is gone.
      #: (String) -> void
      def clear_shown(language)
        i = 0
        while i < @buffers.count
          buffer = @buffers.buffer_at(i)
          buffer.clear_diagnostics if buffer.filetype == language && !buffer.diagnostics.empty?
          i += 1
        end
      end

      #: (untyped) -> Domain::Diagnostic?
      def diagnostic_of(item)
        return nil unless item.is_a?(Hash)
        range = item["range"]
        start = range.is_a?(Hash) ? range["start"] : nil
        return nil unless start.is_a?(Hash)
        severity = item["severity"]
        message = item["message"]
        Domain::Diagnostic.new(row: count_of(start["line"]), col: count_of(start["character"]), severity: severity.is_a?(Integer) ? bounded(severity.to_i, 1, 4) : 1, message: message.is_a?(String) ? Domain::ControlText.line(message.to_s, MESSAGE_LIMIT) : "")
      end

      #: (Integer, Integer, Integer) -> Integer
      def bounded(value, low, high)
        return low if value < low
        return high if value > high
        value
      end

      # A non-negative integer from a JSON value, 0 for anything else.
      #: (untyped) -> Integer
      def count_of(value)
        value.is_a?(Integer) ? [value.to_i, 0].max : 0
      end

      # Tells a running server about the buffers of its file type.
      #: (Domain::LanguageServer) -> void
      def sync(server)
        server.tick = server.tick + 1
        i = 0
        while i < @buffers.count
          buffer = @buffers.buffer_at(i)
          sync_buffer(server, buffer) if buffer.filetype == server.language && !buffer.path.empty?
          i += 1
        end
        server.versions.keys.each do |uri|
          next if server.seen[uri] == server.tick
          notify(server, "textDocument/didClose", { "textDocument" => { "uri" => uri } })
          server.forget(uri)
        end
      end

      #: (Domain::LanguageServer, Domain::Buffer) -> void
      def sync_buffer(server, buffer)
        uri = uri_of(buffer.path)
        server.seen[uri] = server.tick
        version = server.versions[uri]
        if version.nil?
          remember(server, uri, buffer, 1)
          notify(server, "textDocument/didOpen", { "textDocument" => { "uri" => uri, "languageId" => server.language, "version" => 1, "text" => buffer.to_text } })
          return
        end
        if server.changes[uri] != buffer.changes || server.closed[uri] != buffer.closed_count
          remember(server, uri, buffer, version.to_i + 1)
          notify(server, "textDocument/didChange", { "textDocument" => { "uri" => uri, "version" => version.to_i + 1 }, "contentChanges" => [{ "text" => buffer.to_text }] })
        end
        notify(server, "textDocument/didSave", { "textDocument" => { "uri" => uri } }) if @saves.include?(buffer.id)
      end

      #: (Domain::LanguageServer, String, Domain::Buffer, Integer) -> void
      def remember(server, uri, buffer, version)
        server.versions[uri] = version
        server.changes[uri] = buffer.changes
        server.closed[uri] = buffer.closed_count
      end

      # The file URI of a path, made absolute against the working
      # directory, every byte but unreserved ones and slashes escaped. The
      # protocol names documents by file URIs; the scheme and the slashes
      # are joined here, so no link appears in the source.
      #: (String) -> String
      def uri_of(path)
        absolute = path.start_with?("/") ? path : "#{@files.cwd}/#{path}"
        out = +FILE_SCHEME
        out << "//"
        i = 0
        while i < absolute.bytesize
          b = absolute.getbyte(i).to_i
          if unreserved?(b)
            out << b.chr
          else
            out << format("%%%02X", b)
          end
          i += 1
        end
        out
      end

      #: (Integer) -> bool
      def unreserved?(b)
        (b >= 97 && b <= 122) || (b >= 65 && b <= 90) || (b >= 48 && b <= 57) || b == 45 || b == 46 || b == 95 || b == 126 || b == 47
      end

      #: (Domain::LanguageServer, String, untyped) -> Integer
      def request(server, name, params)
        id = server.take_id
        value = { "jsonrpc" => "2.0", "id" => id, "method" => name }
        value["params"] = params unless params.nil?
        deliver(server, value)
        id
      end

      #: (Domain::LanguageServer, String, untyped) -> void
      def notify(server, name, params)
        value = { "jsonrpc" => "2.0", "method" => name }
        value["params"] = params unless params.nil?
        deliver(server, value)
      end

      # Writes one message; a server whose input is broken has crashed.
      #: (Domain::LanguageServer, Hash[String, untyped]) -> void
      def deliver(server, value)
        return if server.handle == 0
        crash(server) unless @processes.write(server.handle, Domain::RpcFramer.frame(Json.generate(value)))
      end
    end
  end
end
