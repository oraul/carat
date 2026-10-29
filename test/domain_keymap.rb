require_relative "../carat"
require_relative "../carat/testing"

t = Carat::Testing.new("domain_keymap")
D = Carat::Domain

config = Carat::Json.parse(D::DEFAULT_CONFIG_JSON)
keymap = D::Keymap.build(config["keymaps"], config["leader"])
t.assert_equal([], keymap.errors, "default configuration has no keymap errors")

def codes(text)
  Carat::Domain::KeyNotation.parse(text, " ").codes
end

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
  ["unbound key", [:normal, "z"], [:none, nil]],
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
custom = D::Keymap.build({ "normal" => { "a" => "one.a", "ab" => "one.ab", "<Nope>" => "x", "j" => "cursor.down", "k" => 5, "" => "empty" }, "bogus" => {} }, " ")
t.table([
  ["a matches and is a prefix", "a", [:match_prefix, "one.a"]],
  ["ab matches", "ab", [:match, "one.ab"]],
  ["j still bound after a bad key", "j", [:match, "cursor.down"]],
  ["k with a non-string value is unbound", "k", [:none, nil]]
]) do |text|
  match = custom.lookup(:normal, codes(text))
  [match.kind, match.value]
end
t.assert_equal([
  "normal.<Nope>: unknown key <Nope>",
  "normal.k: value must be an action name or a key sequence",
  "normal.: empty key",
  "bogus: unknown mode"
], custom.errors, "malformed bindings are reported with mode and key")

# Unbinding with null.
unbound = D::Keymap.build({ "normal" => { "j" => "cursor.down" } }, " ")
unbound.add(:normal, "j", nil, " ")
t.assert_equal(:none, unbound.lookup(:normal, codes("j")).kind, "null unbinds a key")

t.finish
