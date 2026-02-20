class ReeJson::FromJson
  include Ree::FnDSL

  fn :from_json

  ParseJsonError = Class.new(StandardError)

  contract(
    String,
    Ksplat[
      symbol_keys?: Bool,
      RestKeys => Any
    ] => Any
  ).throws(ParseJsonError)
  def call(object, **opts)
    options = {}

    if opts.delete(:symbol_keys)
      options[:symbolize_names] = true
    end

    JSON.parse(object, **options)
  rescue JSON::ParserError, ArgumentError, EncodingError, TypeError
    raise ParseJsonError.new
  end
end
