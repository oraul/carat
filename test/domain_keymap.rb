require_relative "../carat"
require_relative "../carat/testing"

# The test is this module's main. test/runner/run_all.rb runs it by name
# with every other test in one program; the guard at the end runs it when
# the file is compiled on its own (make test-one).
module DomainKeymapTest
  D = Carat::Domain

  def self.codes(text)
    Carat::Domain::KeyNotation.parse(text, " ").codes
  end

  # A plugin's defaults go in first and the configuration last, so the
  # configuration replaces or removes them and leaves the rest alone.
  PLUGIN = ["keymap.normal <leader>hh plugin.hello.greet", "keymap.normal <leader>hx plugin.hello.extra"]

  # The configuration of text read as a trusted file named .caratrc, so
  # key sequences bind, with a Space leader after it.
  #: (String) -> Carat::Domain::Config
  def self.project(text)
    config = D::Config.new
    config.read(".caratrc", text + "keymap.leader <Space>\n", true)
    config
  end

  # Every action name the default lines bind, so the defaults check clean
  # against them.
  #: (Carat::Domain::Config) -> Hash[String, bool]
  def self.bound_actions(config)
    known = D::Keymap.no_actions
    i = 0
    while i < config.count
      line = config.line_at(i)
      known[line.words[1].to_s] = true if line.scope == "keymap" && line.words.length == 2
      i += 1
    end
    known
  end

  def self.main
    t = Carat::Testing.new("domain_keymap")

    config = D::Config.new
    config.read("config/default.caratrc", D::DEFAULT_CARATRC, true)
    keymap = D::Keymap.new
    keymap.add_checked(config, bound_actions(config))
    t.assert_equal([], config.report, "default configuration has no keymap problems")
    t.assert_equal("<Space>", D::Keymap.leader_from(config), "the default leader is Space")

    # Lookups against the default configuration: rows are
    # [label, [mode, notation], [kind, value]].
    t.table([
      ["j in normal", [:normal, "j"], [:match, "cursor.down"]],
      ["arrow in normal", [:normal, "<Down>"], [:match, "cursor.down"]],
      ["escape in insert", [:insert, "<Esc>"], [:match, "mode.normal"]],
      ["colon in normal", [:normal, ":"], [:match, "mode.cmdline"]],
      ["g is a prefix", [:normal, "g"], [:prefix, nil]],
      ["gg completes", [:normal, "gg"], [:match, "cursor.buffer_start"]],
      ["leader is a prefix", [:normal, "<leader>"], [:prefix, nil]],
      ["leader w remaps", [:normal, "<leader>w"], [:match, ":w<CR>"]],
      ["unbound key", [:normal, "Q"], [:none, nil]],
      ["unbound after prefix", [:normal, "gz"], [:none, nil]],
      ["mode with no bindings", [:replace, "j"], [:none, nil]],
      ["control r", [:normal, "<C-r>"], [:match, "history.redo"]],
      ["backspace in cmdline", [:cmdline, "<BS>"], [:match, "cmdline.backspace"]],
      ["d is an operator, not a prefix", [:normal, "d"], [:match, "operator.delete"]],
      ["dd is not a sequence", [:normal, "dd"], [:none, nil]],
      ["quote selects a register", [:normal, "\""], [:match, "register.select"]],
      ["w in operator-pending mode", [:operator_pending, "w"], [:match, "motion.word_forward"]],
      ["i is a prefix in operator-pending mode", [:operator_pending, "i"], [:prefix, nil]],
      ["iw in operator-pending mode", [:operator_pending, "iw"], [:match, "textobject.inner_word"]],
      ["a( in operator-pending mode", [:operator_pending, "a("], [:match, "textobject.a_paren"]],
      ["d in operator-pending mode doubles", [:operator_pending, "d"], [:match, "operator.delete"]],
      ["escape in operator-pending mode", [:operator_pending, "<Esc>"], [:match, "mode.normal"]],
      ["iw is not bound in normal mode", [:normal, "iw"], [:none, nil]],
      ["control w is a prefix", [:normal, "<C-w>"], [:prefix, nil]],
      ["control w s splits", [:normal, "<C-w>s"], [:match, "window.split"]],
      ["control w v splits vertically", [:normal, "<C-w>v"], [:match, "window.vsplit"]],
      ["control w equals equalizes", [:normal, "<C-w>="], [:match, "window.equalize"]],
      ["control w q quits the window", [:normal, "<C-w>q"], [:match, "window.quit"]],
      ["gt goes to the next tab page", [:normal, "gt"], [:match, "tab.next"]],
      ["gT goes to the previous tab page", [:normal, "gT"], [:match, "tab.previous"]]
    ]) do |input|
      match = keymap.lookup(input[0], codes(input[1]))
      [match.kind, match.value]
    end

    # A custom map with an ambiguous prefix.
    custom_config = project("keymap.normal a one.a\nkeymap.normal ab one.ab\nkeymap.normal <Nope> x\nkeymap.normal j cursor.down\nkeymap.normal k\nkeymap.normal \"\" empty\nkeymap.bogus x y\nkeymap.normal l \"\"\n")
    custom = D::Keymap.new
    known = D::Keymap.no_actions
    known["one.a"] = true
    known["one.ab"] = true
    known["cursor.down"] = true
    custom.add_checked(custom_config, known)
    t.table([
      ["a matches and is a prefix", "a", [:match_prefix, "one.a"]],
      ["ab matches", "ab", [:match, "one.ab"]],
      ["j still bound after a bad key", "j", [:match, "cursor.down"]],
      ["k without an action is unbound", "k", [:none, nil]],
      ["l with an empty action is unbound", "l", [:none, nil]]
    ]) do |text|
      match = custom.lookup(:normal, codes(text.to_s))
      [match.kind, match.value]
    end
    t.assert_equal([
      ".caratrc:3: unknown key <Nope>",
      ".caratrc:5: keymap.normal takes keys and an action",
      ".caratrc:6: empty key",
      ".caratrc:7: unknown mode bogus",
      ".caratrc:8: empty action"
    ], custom_config.report, "malformed bindings are reported with the file and line")

    # Unbinding with none, and a later line winning.
    unbound = D::Keymap.new
    unbound.add_checked(project("keymap.normal j cursor.down\nkeymap.normal k cursor.up\nkeymap.normal j none\nkeymap.normal k cursor.down\n"), known)
    t.assert_equal([:none, "cursor.down"], [unbound.lookup(:normal, codes("j")).kind, unbound.lookup(:normal, codes("k")).value], "none unbinds a key and a later line wins")

    t.table([
      ["plugin binding stays when the configuration is silent", "", [[:match, "plugin.hello.greet"], [:match, "plugin.hello.extra"]]],
      ["configuration replaces the plugin binding", "keymap.normal <leader>hh cursor.down\n", [[:match, "cursor.down"], [:match, "plugin.hello.extra"]]],
      ["configuration removes the plugin binding", "keymap.normal <leader>hh none\n", [[:none, nil], [:match, "plugin.hello.extra"]]],
      ["configuration adds a longer binding", "keymap.normal <leader>hhh cursor.up\n", [[:match_prefix, "plugin.hello.greet"], [:match, "plugin.hello.extra"]]]
    ]) do |user|
      merged = D::Keymap.new
      merged.add_lines(PLUGIN, " ", "hello")
      user_known = D::Keymap.no_actions
      user_known["cursor.down"] = true
      user_known["cursor.up"] = true
      merged.add_checked(project(user.to_s), user_known)
      a = merged.lookup(:normal, codes("<leader>hh"))
      b = merged.lookup(:normal, codes("<leader>hx"))
      [[a.kind, a.value], [b.kind, b.value]]
    end
    merged = D::Keymap.new
    merged.add_lines(["keymap.nope a b", "5", "option.x 1", "keymap.normal \"bad x.y", "# a comment", "keymap.leader x"], " ", "probe")
    merged.add_lines(nil, " ", "probe")
    t.assert_equal(["keymap.nope a b: unknown mode nope", "5: invalid key", "option.x 1: not a keymap line", "keymap.normal \"bad x.y: unterminated quote", "keymap.leader x: a plugin cannot set keymap.leader"], merged.errors, "add_lines records errors by line and ignores a non-list")
    scratch = D::Keymap.from_lines(["keymap.normal <CR> plugin.probe.open", "keymap.normal q plugin.probe.close"], " ")
    t.assert_equal([[], "plugin.probe.open", "plugin.probe.close"], [scratch.errors, scratch.lookup(:normal, codes("<CR>")).value, scratch.lookup(:normal, codes("q")).value], "from_lines builds a scratch keymap")

    # Owners: a plugin's bindings can be removed with it, another plugin
    # cannot take its keys, and the configuration replaces either.
    owned = D::Keymap.new
    owned.add_lines(["keymap.normal <leader>pp plugin.probe.go", "keymap.normal <leader>pq plugin.probe.quit"], " ", "probe")
    owned.add_lines(["keymap.normal <leader>pp plugin.other.go", "keymap.normal <leader>oo plugin.other.go"], " ", "other")
    t.assert_equal([["normal.<leader>pp is already bound by plugin probe"], "plugin.probe.go", "probe"], [owned.conflicts, owned.lookup(:normal, codes("<leader>pp")).value, owned.holder_of(:normal, codes("<leader>pp"))], "a second plugin's binding of held keys is refused and recorded")
    owned.remove_owner("probe")
    t.assert_equal([:none, :none, :match], [owned.lookup(:normal, codes("<leader>pp")).kind, owned.lookup(:normal, codes("<leader>p")).kind, owned.lookup(:normal, codes("<leader>oo")).kind], "removing an owner drops its bindings and the prefixes left empty, and keeps the others")
    owned.add_lines(["keymap.normal <leader>oo cursor.down"], " ", "")
    owned.remove_owner("other")
    t.assert_equal([:match, "cursor.down"], [owned.lookup(:normal, codes("<leader>oo")).kind, owned.lookup(:normal, codes("<leader>oo")).value], "the configuration replaces a plugin binding and keeps it when the plugin goes")
    # Checked loading: an action name outside the known set is refused and
    # reported with the file and line; key sequences and known actions go
    # in, and every other problem is reported the same way.
    checked = D::Keymap.new
    checked_known = D::Keymap.no_actions
    checked_known["cursor.down"] = true
    checked_config = project("keymap.normal j cursor.down\nkeymap.normal zq foo.bar\nkeymap.normal zz :w<CR>\nkeymap.normal <Nope> cursor.down\nkeymap.nope x cursor.down\n")
    checked.add_checked(checked_config, checked_known)
    t.assert_equal([
      ".caratrc:2: unknown action foo.bar",
      ".caratrc:4: unknown key <Nope>",
      ".caratrc:5: unknown mode nope"
    ], checked_config.report, "checked loading reports unknown actions and malformed keys with the file and line")
    t.assert_equal([:match, :none, :match], [checked.lookup(:normal, codes("j")).kind, checked.lookup(:normal, codes("zq")).kind, checked.lookup(:normal, codes("zz")).kind], "the refused binding is not added and the others are")

    # The leader: the last good keymap.leader line, Vim's backslash
    # without one; a bad one is reported and skipped.
    leaders = D::Config.new
    leaders.read(".caratrc", "keymap.leader ,\nkeymap.leader a b\nkeymap.leader <Nope>\nkeymap.leader \"\"\n", true)
    D::Keymap.new.add_checked(leaders, known)
    t.assert_equal([",", ".caratrc:2: keymap.leader takes one key", ".caratrc:3: unknown key <Nope>", ".caratrc:4: keymap.leader takes one key"], [D::Keymap.leader_from(leaders)] + leaders.report, "the leader is the last good leader line")
    t.assert_equal("\\", D::Keymap.leader_from(D::Config.new), "the leader is a backslash when no line sets it")

    t.assert_equal([true, false, false], [D::Keymap.action_name?("plugin.a.b"), D::Keymap.action_name?(":w<CR>"), D::Keymap.action_name?("plain")], "an action name has namespace segments, a key sequence does not")

    # Hostile bytes: the action check reads bytes and never raises, and a
    # binding with an illegal byte is a reported line in every way
    # bindings arrive. Rows are [label, value, action name].
    t.table([
      ["a lone byte after a segment", "plugin.\xFF", false],
      ["a lone byte inside a name", "a\xFF.b", false],
      ["an overlong form", "plugin.\xC0\xAF", false],
      ["UTF-8 is not an action name either", "plugin.d\u00EDa", false],
      ["a trailing dot", "plugin.", false],
      ["an empty value", "", false],
      ["one segment and the action", "cursor.down", true]
    ]) do |value|
      D::Keymap.action_name?(value.to_s)
    end
    hostile_known = D::Keymap.no_actions
    hostile_known["cursor.down"] = true
    hostile_config = D::Config.new
    hostile_config.read("~/.config/carat/caratrc", "keymap.normal x a\xFF.b\nkeymap.normal \xE9 cursor.down\nkeymap.normal j cursor.down\n", true)
    hostile = D::Keymap.new
    hostile.add_checked(hostile_config, hostile_known)
    t.assert_equal([["~/.config/carat/caratrc:1: illegal byte", "~/.config/carat/caratrc:2: illegal byte"], :none, :match], [hostile_config.report, hostile.lookup(:normal, codes("x")).kind, hostile.lookup(:normal, codes("j")).kind], "a trusted binding with an illegal byte is reported and skipped")
    hostile_lines = D::Keymap.from_lines(["keymap.normal q plugin.p.\xFF", "keymap.normal w plugin.p.ok"], " ")
    t.assert_equal([["keymap.normal q plugin.p.\xFF: illegal byte"], :none, "plugin.p.ok"], [hostile_lines.errors, hostile_lines.lookup(:normal, codes("q")).kind, hostile_lines.lookup(:normal, codes("w")).value], "a plugin's binding with an illegal byte is an error of its line")

    # Long bindings: at most 64 keys, so the trie, which removing a
    # plugin's bindings walks recursively, stays shallow.
    long_config = project("keymap.normal #{"j" * 65} cursor.down\nkeymap.normal #{"j" * 64} cursor.down\n")
    long = D::Keymap.new
    long.add_checked(long_config, known)
    t.assert_equal([[".caratrc:1: more than 64 keys"], :none, :match], [long_config.report, long.lookup(:normal, codes("j" * 65)).kind, long.lookup(:normal, codes("j" * 64)).kind], "a binding of 65 keys is reported and skipped, one of 64 is bound")
    too_long = "keymap.normal #{"x" * 65} plugin.probe.go"
    long_owned = D::Keymap.new
    long_owned.add_lines([too_long, "keymap.normal #{"y" * 64} plugin.probe.go"], " ", "probe")
    t.assert_equal([["#{too_long}: more than 64 keys"], :none, :match], [long_owned.errors, long_owned.lookup(:normal, codes("x")).kind, long_owned.lookup(:normal, codes("y" * 64)).kind], "a plugin's binding of 65 keys is an error of its line and nothing of it is bound")
    long_owned.remove_owner("probe")
    t.assert_equal([:none, :none], [long_owned.lookup(:normal, codes("y" * 64)).kind, long_owned.lookup(:normal, codes("y")).kind], "removing the plugin drops its 64-key binding and every prefix of it")

    t.finish
  end
end

DomainKeymapTest.main if __FILE__ == $0
