# frozen_string_literal: true

class ReeHash::BuildFilterKeys
  include Ree::FnDSL

  fn :build_filter_keys do
    link 'ree_hash/contracts/hash_keys_contract', -> { HashKeysContract }
  end

  contract(HashKeysContract => HashOf[Symbol, Hash])
  def call(keys)
    result = {}

    keys.each do |key|
      if key.is_a?(Symbol)
        result[key] = {}
      elsif key.is_a?(Hash)
        key.each do |k, key|
          result[k] = call(key)
        end
      end
    end

    result
  end
end