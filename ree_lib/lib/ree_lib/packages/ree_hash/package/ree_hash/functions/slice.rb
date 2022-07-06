# frozen_string_literal: true

class ReeHash::Slice
  include Ree::FnDSL

  fn :slice do
    def_error { MissingKeyErr }
  end

  doc(<<~DOC)
    Replaces the hash with only the given keys.
    Returns a hash containing the removed key/value pairs.
    
      hash = { a: 1, b: 2, c: 3, d: 4 }
      slice(hash, :a, :b)  # => {:c=>3, :d=>4}
  DOC
  contract(
    Hash,
    SplatOf[Symbol],
    Ksplat[
      raise?: Bool
    ] => Hash
  ).throws(MissingKeyErr)
  def call(hash, *keys, **opts)
    sliced_hash = {}

    keys.each do |key|
      if hash.has_key?(key)
        sliced_hash.store(key, hash[key])
      elsif opts[:raise]
        raise MissingKeyErr.new("target hash does not have key `#{key.inspect}`")
      end
    end

    sliced_hash
  end
end