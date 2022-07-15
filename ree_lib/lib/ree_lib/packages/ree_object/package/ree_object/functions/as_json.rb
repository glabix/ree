# frozen_string_literal: true

class ReeObject::AsJson
  include Ree::FnDSL

  fn :as_json do
    def_error { RecursiveObjectErr }
  end
  
  BASIC_TYPES = [
    Date, Time, Numeric, String, FalseClass, TrueClass, NilClass, Symbol,
    Module, Class
  ].freeze

  contract(
    Any => Or[Hash, ArrayOf[Any], *BASIC_TYPES]
  ).throws(RecursiveObjectErr)
  def call(obj)
    recursively_convert(obj, {}, {})
  end

  private

  def recursively_convert(obj, acc, cache)
    ancestors = obj.class.ancestors

    if ancestors.intersection(BASIC_TYPES).size > 0
      obj
    elsif obj.is_a?(Array)
      convert_array(obj, acc, cache)
    elsif obj.is_a?(Hash)
      convert_hash(obj, acc, cache)
    elsif obj.respond_to?(:to_h)
      convert_hash(obj.to_h, acc, cache)
    else
      convert_object(obj, acc, cache)
    end
  end

  def convert_array(obj, acc, cache)
    obj.map { |el| recursively_convert(el, {}, cache) }
  end

  def convert_hash(obj, acc, cache)
    obj.each do |k, v|
      key_sym = k.to_sym
      acc[key_sym] = recursively_convert(v, {}, cache)
    end

    acc
  end

  def convert_object(obj, acc, cache)
    return obj if obj.is_a?(Class) || obj.is_a?(Module)

    if cache.key?(obj.object_id)
      raise RecursiveObjectErr, "Recursive object found: #{obj}"
    end

    cache[obj.object_id] = acc
    
    obj.instance_variables.each do |var|
      key_name = var.to_s.delete("@")
      key_sym = key_name.to_sym

      key = key_sym
      value = obj.instance_variable_get(var)

      acc[key] = recursively_convert(value, {}, cache)
    end

    acc
  end
end