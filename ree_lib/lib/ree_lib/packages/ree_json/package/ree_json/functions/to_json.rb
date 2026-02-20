class ReeJson::ToJson
  include Ree::FnDSL

  fn :to_json

  doc(<<~DOC)
    Dumps arbitrary object to json.
      to_json({id: 1}) # => "{\"id\":1}"
  DOC

  contract(Any => String)
  def call(object)
    JSON.generate(object)
  end
end
