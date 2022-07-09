# frozen_string_literal: true

class ReeObject::DeepFreeze
  include Ree::FnDSL

  fn :deep_freeze

  doc(<<~DOC)
    Deeply freezes object.
      
    Examples of usage:
      deep_freeze(Object.new)
  DOC

  contract(Any => Any)
  def call(obj)
    recursively_freeze(obj, {})
  end

  private

  def recursively_freeze(obj, cache)
    if obj.class == Array
      freeze_array(obj, cache)
    elsif obj.class == Hash
      freeze_hash(obj, cache)
    else
      freeze_obj(obj, cache)
    end
  end

  def freeze_array(array, cache)
    array.each { recursively_freeze(_1, cache) }
    array.freeze
  end

  def freeze_hash(hash, cache)
    hash.default.freeze

    hash.each do |k, v|
      recursively_freeze(k, cache)
      recursively_freeze(v, cache)
    end

    hash.freeze
  end

  def freeze_obj(obj, cache)
    return obj if obj.is_a?(Class) || obj.is_a?(Module)
    return cache[obj.object_id] if cache.key?(obj.object_id)

    cache[obj.object_id] = obj

    obj.instance_variables.each do |var|
      recursively_freeze(obj.instance_variable_get(var), cache)
    end

    obj.freeze
  end
end
