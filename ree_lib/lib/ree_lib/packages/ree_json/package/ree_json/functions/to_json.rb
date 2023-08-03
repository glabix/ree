class ReeJson::ToJson
  include Ree::FnDSL

  fn :to_json do
    link 'ree_json/constants', -> {
      ESCAPE_MODES & DEFAULT_OPTIONS & MODES & TIME_FORMATS
    }
  end

  doc(<<~DOC)
    Dumps arbitrary object to json using specific dump mode.
      to_json({id: 1}) # => "{\"id\":1}"
      to_json({id: 1}, mode: :object) # => "{\":id\":{\"^o\":\"Object\"}}"

    List of all available Ksplat options could be found here:
    https://github.com/ohler55/oj/blob/develop/pages/Modes.md
  DOC

  contract(
    Any,
    Ksplat[
      mode?: Or[*MODES],
      escape_mode?: Or[*ESCAPE_MODES],
      float_precision?: Integer,
      time_format?: Or[*TIME_FORMATS],
      use_as_json?: Bool,
      use_raw_json?: Bool,
      use_to_hash?: Bool,
      use_to_json?: Bool,
      RestKeys => Any
    ] => String
  ).throws(ArgumentError, TypeError)
  def call(object, **opts)
    options = DEFAULT_OPTIONS
      .merge(opts)

    Oj.dump(object, options)
  end
end