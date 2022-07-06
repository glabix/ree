class ReeJson::Constants
  # see detailed docsumentation for modes
  # https://github.com/ohler55/oj/blob/develop/pages/Modes.md

  MODES = [
    :strict,
    :null,
    :compat,
    :json,
    :rails,
    :object,
    :custom,
    :wab,
  ]

  ESCAPE_MODES = [
    :newline, # allows unescaped newlines in the output.
    :json, # follows the JSON specification. This is the default mode.
    :xss_safe, # escapes HTML and XML characters such as & and <.
    :ascii, # escapes all non-ascii or characters with the hi-bit set.
    :unicode_xss, # escapes a special unicodes and is xss safe.
  ]

  TIME_FORMATS = []

  DEFAULT_OPTIONS = {
    time_format: :xmlschema,
    use_as_json: true
  }.freeze
end