class ReeJson::FromJson
  include Ree::FnDSL

  fn :from_json do
    link 'ree_json/constants', -> {
      DEFAULT_OPTIONS & MODES & ESCAPE_MODES & TIME_FORMATS
    }
  end

  ParseJsonError = Class.new(StandardError)

  contract(
    Any,
    Ksplat[
      mode?: Or[*MODES],
      symbol_keys?: Bool,
      RestKeys => Any
    ] => Any
  ).throws(ParseJsonError)
  def call(object, **opts)
    options = DEFAULT_OPTIONS
      .merge(opts)

    Oj.load(object, options)
  rescue ArgumentError, EncodingError, TypeError
    raise ParseJsonError.new
  end
end