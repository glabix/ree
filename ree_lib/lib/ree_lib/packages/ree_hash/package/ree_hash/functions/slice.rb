# frozen_string_literal: true

class ReeHash::Slice
  include Ree::FnDSL

  fn :slice do
    link :build_filter_keys
    link 'ree_hash/contracts/hash_keys_contract', -> { HashKeysContract }
    def_error { MissingKeyErr }
    def_error { InvalidFilterKey }
  end

  doc(<<~DOC)
    Replaces the hash with only the given keys.
    Returns a hash containing the removed key/value pairs.
    
      hash = { a: 1, b: {e: 2, f: 1}, c: 3, d: 4 }
      slice(hash, [:a, :b])  # => {a: 1, b: 2}
      slice(hash, [:a, b: [:e]])  # => {a: 1, b: {e: 2}}
  DOC

  contract(
    Hash,
    HashKeysContract,
    Ksplat[
      raise?: Bool
    ] => Hash
  ).throws(MissingKeyErr, InvalidFilterKey)
  def call(hash, keys, **opts)
    filter_keys = build_filter_keys(keys)
    recursively_slice(hash, filter_keys, !!opts[:raise])
  end

  private

  def recursively_slice(hash, filter_keys, raise_if_missing)
    result = {}

    filter_keys.each do |filter_k, filter_v|
      if !hash.has_key?(filter_k)
        if raise_if_missing
          raise MissingKeyErr.new("missing key `#{filter_k.inspect}`")
        else
          next
        end
      end

      value = hash[filter_k]

      if filter_v.empty?
        result[filter_k] = value
        next
      end

      if value.is_a?(Array)
        result[filter_k] = value.map do |v|
          if v.is_a?(Hash)
            recursively_slice(v, filter_v, raise_if_missing)
          else
            raise InvalidFilterKey.new("invalid filter key #{filter_v.inspect} for value: #{v.inspect}")
          end
        end
      elsif value.is_a?(Hash)
        result[filter_k] = recursively_slice(value, filter_v, raise_if_missing)
      else
        raise InvalidFilterKey.new("invalid filter key #{filter_v.inspect} for value: #{value.inspect}")
      end
    end

    result
  end
end