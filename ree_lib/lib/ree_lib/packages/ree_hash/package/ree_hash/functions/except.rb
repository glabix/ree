# frozen_string_literal: true

class ReeHash::Except
  include Ree::FnDSL

  fn :except

  doc(<<~DOC)
    Returns a hash that includes everything except given keys.
      hash = { a: true, b: false, c: nil }
      except(hash, :c)     # => { a: true, b: false }
      except(hash, :a, :b) # => { c: nil }
  DOC
  contract(Hash, SplatOf[Symbol] => Hash)
  def call(hash, *keys)
    result_hash = {}    
    result_keys = hash.keys - keys

    result_keys.each do |key|
      result_hash.store(key, hash[key])
    end

    result_hash
  end
end