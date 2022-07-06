class ReeJson::FromJson
  include Ree::FnDSL

  fn :from_json do
    link 'ree_json/constants', -> {
      DEFAULT_OPTIONS & MODES  & ESCAPE_MODES & TIME_FORMATS
    }
  end

  contract(
    Any,
    Kwargs[
      mode: Or[*MODES]
    ],
    Ksplat[
      symbol_keys?: Bool,
      RestKeys => Any
    ] => Hash
  ).throws(ArgumentError)
  def call(object, mode: :rails, **opts)
    options = DEFAULT_OPTIONS
      .dup
      .merge(
        opts.merge(mode: mode)
      )

    Oj.load(object, options)
  end
end