# frozen_string_literal: true

class ReeHash::SymbolizeKeys
  include Ree::FnDSL

  fn :symbolize_keys do
    link :transform_keys
  end

  doc("Converts keys to Symbol if possible, deep is by default")
  contract(Hash => Hash)
  def call(hash)
    transform_keys(hash) { |key| key.to_sym }
  end
end