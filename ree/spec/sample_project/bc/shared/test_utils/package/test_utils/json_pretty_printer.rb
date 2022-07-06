class TestUtils::JsonPrettyPrinter
  include Ree::FnDSL

  fn :json_pretty_printer

  def call(hash)
    JSON.pretty_generate(data)
  end
end