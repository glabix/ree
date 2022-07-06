# frozen_string_literal: true

class ReeHash::Merge
  include Ree::FnDSL

  fn :merge

  doc(<<~DOC)
    Returns a new hash with +first_hash+ and +other_hash+ merged recursively.
    
      h1 = { a: true, b: { c: [1, 2, 3] } }
      h2 = { a: false, b: { x: [3, 4, 5] } }
    
      merge(h1, h2, deep: true) # => { a: false, b: { c: [1, 2, 3], x: [3, 4, 5] } }
      merge(h1, h2, deep: false) # => { a: false, b: { x: [3, 4, 5] } }
    
    Like with Hash#merge in the standard library, a block can be provided
    to merge values:
    
      h1 = { a: 100, b: 200, c: { c1: 100 } }
      h2 = { b: 250, c: { c1: 200 } }

      merge(h1, h2) { |key, this_val, other_val| this_val + other_val }
        => { a: 100, b: 450, c: { c1: 300 } }
  DOC
  contract(
    Hash,
    Hash,
    Kwargs[deep: Bool],
    Optblock => Hash
  )
  def call(first_hash, other_hash, deep: true, &block)
    recursively_merge(first_hash, other_hash, deep, &block)
  end

  private

  def recursively_merge(first_hash, other_hash, deep, &block)
    first_hash.merge(other_hash) do |key, first_val, other_val|
      if first_val.is_a?(Hash) && other_val.is_a?(Hash) && deep
        recursively_merge(first_val, other_val, deep)
      elsif block_given?
        yield key, first_val, other_val
      else
        other_val
      end
    end
  end
end