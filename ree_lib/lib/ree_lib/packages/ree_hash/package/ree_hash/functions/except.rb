# frozen_string_literal: true

class ReeHash::Except
  include Ree::FnDSL

  fn :except do
    link :build_filter_keys
    link 'ree_hash/contracts/hash_keys_contract', -> { HashKeysContract }
  end

  doc(<<~DOC)
    Returns a hash that includes everything except given keys.
    You can pass a symbol or a hash with array of symbols as a key.
    The <tt>global_except:</tt> option excepts key in a hash recursively. 

      hash = { a: true, b: false, c: nil, d: { e: 'e', f: 'f' }, f: 'f', setting: { id: 1, number: 1 } }
      except(hash, [:c])     # => { a: true, b: false, d: { e: 'e', f: 'f' }, f: 'f' , setting: { id: 1, number: 1 } }
      except(hash, [:a, :b]) # => { c: nil, d: { e: 'e', f: 'f'}, f: 'f', setting: { id: 1, number: 1 } }
      except(hash, [:a, :b, d: [:f]]) #=> { c: nil, d: { e: 'e' }, f: 'f', setting: { id: 1, number: 1 } }
      except(hash, [:a, :b, d: [:f], setting: [:id]] }) #=> { c: nil, d: { e: 'e' }, f: 'f', setting: { number: 1 } }
      except(hash, [:a], global_except: [:f]) #=> { b: false, c: nil, d: { e: 'e' }, setting: { id: 1, number: 1 } }
  DOC

  contract(
    Hash, 
    HashKeysContract,
    Ksplat[
      global_except?: ArrayOf[Symbol]
    ] => Hash
  )
  def call(hash, keys = [], **opts)
    keys = build_filter_keys(keys)
    global_except_keys = build_filter_keys(opts[:global_except] || [])
    recursively_except(hash, keys, global_except_keys)
  end

  private

  def recursively_except(hash, except_keys, global_except_keys)
    result = {}
    except_keys ||= {}

    result.default = hash.default
    result.default_proc = hash.default_proc if hash.default_proc

    hash.each do |k, v|
      next if global_except_keys.has_key?(k)
      next if except_keys.has_key?(k) && except_keys[k].empty?

      if v.is_a?(Array)
        result[k] = v.map do |item|
          if item.is_a?(Hash)
            recursively_except(item, except_keys[k], global_except_keys)
          else
            item
          end
        end
      elsif v.is_a?(Hash)
        result[k] = recursively_except(
          v, except_keys[k], global_except_keys
        )
      else
        result[k] = v
      end
    end

    result
  end
end