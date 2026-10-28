module Carat
  module Domain
    # Converts between key codes and the Vim spelling used in JSON: plain
    # characters, <CR>, <Esc>, <C-x>, <A-x>, <leader>, <Up>, <F5>, and so on.
    # Names are case-insensitive.
    module KeyNotation
      # The outcome of parsing: the codes, or an error naming the bad key.
      # A Data value: equal by value and frozen.
      class Result < Data.define(:codes, :error)
        #: () -> bool
        def ok?
          error.nil?
        end
      end

      NAMED = {
        "cr" => Key::CR,
        "enter" => Key::CR,
        "return" => Key::CR,
        "nl" => Key::NL,
        "esc" => Key::ESC,
        "tab" => Key::TAB,
        "bs" => Key::BS,
        "space" => Key::SPACE,
        "lt" => 60,
        "bar" => 124,
        "bslash" => 92,
        "del" => Key::DELETE,
        "up" => Key::UP,
        "down" => Key::DOWN,
        "left" => Key::LEFT,
        "right" => Key::RIGHT,
        "home" => Key::HOME,
        "end" => Key::END_KEY,
        "insert" => Key::INSERT,
        "pageup" => Key::PAGE_UP,
        "pagedown" => Key::PAGE_DOWN,
        "f1" => Key::F1,
        "f2" => Key::F2,
        "f3" => Key::F3,
        "f4" => Key::F4,
        "f5" => Key::F5,
        "f6" => Key::F6,
        "f7" => Key::F7,
        "f8" => Key::F8,
        "f9" => Key::F9,
        "f10" => Key::F10,
        "f11" => Key::F11,
        "f12" => Key::F12
      }

      # Parses a key sequence. <leader> expands to the leader text, which is
      # itself parsed (without a leader of its own). A "<...>" with an
      # unknown name is reported as an error; a "<" with no closing ">" is
      # the character itself, as Vim reads it.
      #: (String, String) -> Result
      def self.parse(text, leader)
        codes = []
        chars = text.chars
        i = 0
        while i < chars.length
          c = chars[i]
          if c == "<"
            close = i + 1
            close += 1 while close < chars.length && chars[close] != ">"
            if close >= chars.length
              codes << 60
              i += 1
              next
            end
            name = chars[i + 1, close - i - 1].join
            resolved = resolve(name, leader)
            return Result.new([], "unknown key <#{name}>") if resolved.nil?
            codes.concat(resolved)
            i = close + 1
          else
            codes << c.ord
            i += 1
          end
        end
        Result.new(codes, nil)
      end

      # The codes a <name> stands for, or nil when the name is unknown.
      #: (String, String) -> Array[Integer]?
      def self.resolve(name, leader)
        lower = name.downcase
        if lower == "leader"
          return nil if leader.empty?
          inner = parse(leader, "")
          return inner.ok? ? inner.codes : nil
        end
        named = NAMED[lower]
        return [named] unless named.nil?
        return nil unless name.length == 3
        prefix = lower[0, 2]
        ch = name[2, 1]
        if prefix == "c-"
          ctrl = control_code(ch)
          return ctrl.nil? ? nil : [ctrl]
        end
        return [ch.ord | Key::ALT] if prefix == "a-" || prefix == "m-"
        nil
      end

      # The control code of a key: letters by their alphabet position and
      # the ASCII punctuation Vim accepts after C-.
      #: (String) -> Integer?
      def self.control_code(ch)
        code = ch.downcase.ord
        return code - 96 if code >= 97 && code <= 122
        return 0 if ch == "@"
        return 27 if ch == "["
        return 28 if ch == "\\"
        return 29 if ch == "]"
        return 30 if ch == "^"
        return 31 if ch == "_"
        return 127 if ch == "?"
        nil
      end

      # The notation of one code.
      #: (Integer) -> String
      def self.format(code)
        return "<A-#{format(Key.base(code))}>" if Key.alt?(code)
        special = special_name(code)
        return special unless special.nil?
        return "<C-#{Key.char(code + 96)}>" if code > 0 && code < 32
        return "<C-@>" if code == 0
        Key.char(code)
      end

      #: (Integer) -> String?
      def self.special_name(code)
        case code
        when Key::CR then "<CR>"
        when Key::NL then "<NL>"
        when Key::ESC then "<Esc>"
        when Key::TAB then "<Tab>"
        when Key::BS then "<BS>"
        when Key::SPACE then "<Space>"
        when 60 then "<lt>"
        when Key::DELETE then "<Del>"
        when Key::UP then "<Up>"
        when Key::DOWN then "<Down>"
        when Key::LEFT then "<Left>"
        when Key::RIGHT then "<Right>"
        when Key::HOME then "<Home>"
        when Key::END_KEY then "<End>"
        when Key::INSERT then "<Insert>"
        when Key::PAGE_UP then "<PageUp>"
        when Key::PAGE_DOWN then "<PageDown>"
        when Key::F1 then "<F1>"
        when Key::F2 then "<F2>"
        when Key::F3 then "<F3>"
        when Key::F4 then "<F4>"
        when Key::F5 then "<F5>"
        when Key::F6 then "<F6>"
        when Key::F7 then "<F7>"
        when Key::F8 then "<F8>"
        when Key::F9 then "<F9>"
        when Key::F10 then "<F10>"
        when Key::F11 then "<F11>"
        when Key::F12 then "<F12>"
        when Key::UNKNOWN then "<Unknown>"
        else nil
        end
      end
    end
  end
end
