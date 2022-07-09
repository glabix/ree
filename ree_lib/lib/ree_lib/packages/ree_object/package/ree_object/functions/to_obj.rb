# frozen_string_literal: true

class ReeObject::ToObj
  include Ree::FnDSL

  fn :to_obj do
    link :as_json, import: -> { BASIC_TYPES }
    link :slice, from: :ree_hash
    link :except, from: :ree_hash
    link 'ree_hash/contracts/hash_keys_contract', -> { HashKeysContract }
  end

  contract(
    Any,
    Ksplat[
      include?: HashKeysContract,
      exclude?: HashKeysContract,
      global_exclude?: ArrayOf[Symbol]
    ] => Or[Object, ArrayOf[Object], *BASIC_TYPES]
  ).throws(ArgumentError)
  def call(obj, **opts)
    dump = as_json(obj)

    options = prepare_options(opts)

    if opts[:include]
      dump = slice(dump, options[:include])
    end

    if opts[:exclude]
      dump = except(dump, options[:exclude])
    end

    if opts[:global_exclude]
      dump = except(dump, global_except: options[:global_exclude])
    end

    ancestors = dump.class.ancestors
    return dump if ancestors.intersection(BASIC_TYPES).size > 0
      
    if dump.is_a?(Array)
      build_array(dump)
    else
      recursively_assign(Object.new, dump)
    end
  end

  private

  def build_array(array)
    array.map do |value|
      if value.is_a?(Array)
        build_array(value)
      elsif value.is_a?(Hash)
        recursively_assign(Object.new, value)
      else
        value
      end
    end
  end

  def recursively_assign(obj, hash)
    hash.each do |key, value|
      var = :"@#{key}"

      obj.define_singleton_method key do 
        instance_variable_get(var)
      end

      if value.is_a?(Array)
        obj.instance_variable_set(var, build_array(value))
      elsif value.is_a?(Hash)
        obj.instance_variable_set(var, recursively_assign(Object.new, value))
      else
        obj.instance_variable_set(var, value)
      end
    end
    
    obj
  end

  def prepare_options(opts)
    if opts[:include] && (opts[:exclude] || opts[:global_exclude])
      intersection = opts_keys(opts[:include]).intersection(opts_keys(opts[:exclude] || opts[:global_exclude]))

      if intersection.length > 0
        raise ArgumentError, "Exclude and include have the same values: #{intersection}"
      end
    end

    opts
  end

  def opts_keys(arr)
    arr.reject { |e| e.is_a?(Hash) }
  end
end