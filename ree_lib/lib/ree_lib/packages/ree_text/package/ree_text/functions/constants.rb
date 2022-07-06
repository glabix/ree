# frozen_string_literal: true

class ReeText::Constants
  HTML_ESCAPE = { "&" => "&amp;",  ">" => "&gt;",   "<" => "&lt;", '"' => "&quot;", "'" => "&#39;" }
  JSON_ESCAPE = { "&" => '\u0026', ">" => '\u003e', "<" => '\u003c', "\u2028" => '\u2028', "\u2029" => '\u2029' }
  HTML_ESCAPE_ONCE_REGEXP = /["><']|&(?!([a-zA-Z]+|(#\d+)|(#[xX][\dA-Fa-f]+));)/
  JSON_ESCAPE_REGEXP = /[\u2028\u2029&><]/u
  JS_ESCAPE_MAP = {
    "\\"    => "\\\\",
    "</"    => '<\/',
    "\r\n"  => '\n',
    "\n"    => '\n',
    "\r"    => '\n',
    '"'     => '\\"',
    "'"     => "\\'",
    "`"     => "\\`",
    "$"     => "\\$"
  }

  TAG_NAME_START_REGEXP_SET = "@:A-Z_a-z\u{C0}-\u{D6}\u{D8}-\u{F6}\u{F8}-\u{2FF}\u{370}-\u{37D}\u{37F}-\u{1FFF}" \
  "\u{200C}-\u{200D}\u{2070}-\u{218F}\u{2C00}-\u{2FEF}\u{3001}-\u{D7FF}\u{F900}-\u{FDCF}" \
  "\u{FDF0}-\u{FFFD}\u{10000}-\u{EFFFF}"
  TAG_NAME_START_REGEXP = /[^#{TAG_NAME_START_REGEXP_SET}]/
  TAG_NAME_FOLLOWING_REGEXP = /[^#{TAG_NAME_START_REGEXP_SET}\-.0-9\u{B7}\u{0300}-\u{036F}\u{203F}-\u{2040}]/
  TAG_NAME_REPLACEMENT_CHAR = "_"
end