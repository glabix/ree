# frozen_string_literal: true

class ReeHash::StringifyKeys
  include Ree::FnDSL

  fn :stringify_keys do
    link :transform_keys
  end

  doc("Converts Hash keys to String, deep is by default")
  contract(Hash => Hash)
  def call(hash)
    transform_keys(hash) { |key| key.to_s }
  end
end