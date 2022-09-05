class ReeJson::FromJson
  include Ree::FnDSL

  fn :from_json do
    link 'ree_json/constants', -> {
      DEFAULT_OPTIONS & MODES  & ESCAPE_MODES & TIME_FORMATS
    }
  end

  ParseJsonError = Class.new(StandardError)

  contract(
    Any,
    Kwargs[
      mode: Or[*MODES]
    ],
    Ksplat[
      symbol_keys?: Bool,
      RestKeys => Any
    ] => Hash
  ).throws(ParseJsonError)
  def call(object, mode: :rails, **opts)
    options = DEFAULT_OPTIONS
      .dup
      .merge(
        opts.merge(mode: mode)
      )

    Oj.load(object, options)
  rescue ArgumentError, EncodingError
    raise ParseJsonError.new
  end
end