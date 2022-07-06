# frozen_string_literal: true

class ReeObject::DeepDup
  include Ree::FnDSL

  fn :deep_dup

  contract(
    Any,
    Ksplat[
      freeze?: Bool
    ] => Any
  )
  def call(obj, **opts)
    recursively_dup(obj, opts, {})
  end

  private

  def recursively_dup(obj, opts, cache)
    if obj.is_a?(Array)
      dup_array(obj, opts, cache)
    elsif obj.is_a?(Hash)
      dup_hash(obj, opts, cache)
    else
      dup_object(obj, opts, cache)
    end
  end

  def dup_object(obj, opts, cache)
    return obj if obj.is_a?(Class) || obj.is_a?(Module)
    return cache[obj.object_id] if cache.key?(obj.object_id)

    dup = obj.dup
    cache[obj.object_id] = dup

    dup.instance_variables.each do |var|
      dup.instance_variable_set(
        var, recursively_dup(
          dup.instance_variable_get(var), opts, cache
        )
      )
    end

    dup_singleton_methods(obj, dup)

    opts[:freeze] ? dup.freeze : dup
  end

  def dup_hash(hash, opts, cache)
    dup = {}

    dup.default = recursively_dup(hash.default, opts, cache)
    dup.default_proc = hash.default_proc if hash.default_proc

    hash.each do |k, v|
      dup[recursively_dup(k, opts, cache)] = recursively_dup(v, opts, cache)
    end

    dup_singleton_methods(hash, dup)
    
    opts[:freeze] ? dup.freeze : dup
  end

  def dup_array(array, opts, cache)
    dup = array.map { recursively_dup(_1, opts, cache) }
    dup_singleton_methods(array, dup)
    opts[:freeze] ? dup.freeze : dup
  end

  def dup_singleton_methods(source, target)
    return if source.singleton_methods.empty?

    source.singleton_methods.each do |method_name|
      target.define_singleton_method(
        method_name, &source.method(method_name)
      )
    end
  end
end