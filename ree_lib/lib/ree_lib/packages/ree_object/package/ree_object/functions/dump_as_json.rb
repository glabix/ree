# frozen_string_literal: true

require 'set'

class ReeObject::DumpAsJson
  include Ree::FnDSL

  fn :dump_as_json do
    def_error { RecursiveObjectErr }
  end

  ARRAY = 'array'
  HASH = 'hash'
  PRIMITIVE = 'primitive'
  OBJECT = 'object'

  BASIC_TYPES = [
    Date, Time, Numeric, String, FalseClass, TrueClass, NilClass, Symbol,
    Module, Class
  ].freeze

  contract(
    Any => Or[Hash, ArrayOf[Any], *BASIC_TYPES]
  ).throws(RecursiveObjectErr)
  def call(obj)
    recursively_convert(obj, {})
  end

  private

  def recursively_convert(obj, cache)
    ancestors = obj.class.ancestors

    if ancestors.intersection(BASIC_TYPES).size > 0
      {
        'type' => PRIMITIVE,
        'class' => obj.class.name,
        'value' => dump_primitive(obj)
      }
    elsif obj.is_a?(Array)
      {
        'type' => ARRAY,
        'class' => 'Array',
        'value' => obj.map { recursively_convert(_1, cache) }
      }
    elsif obj.is_a?(Hash)
      {
        'type' => HASH,
        'class' => 'Hash',
        'value' => convert_hash(obj, cache)
      }
    elsif obj.is_a?(Proc)
      raise ArgumentError, "procs are not supported"
    else
      {
        'type' => OBJECT,
        'class' => obj.class.name || (raise ArgumentError.new("anonymous classes are not supported")),
        'value' => convert_object(obj, cache)
      }
    end
  end

  PRIMITIVE_SET = Set.new([Symbol, Date, Time, DateTime, Module, Class])

  def dump_primitive(val)
    if PRIMITIVE_SET.include?(val.class)
      val.to_s
    else
      val
    end
  end

  def convert_hash(obj, cache)
    result = []

    obj.each do |k, v|
      result << [
        recursively_convert(k, cache),
        recursively_convert(v, cache),
      ]
    end

    result
  end

  def convert_object(obj, cache)
    if cache.key?(obj.object_id)
      raise RecursiveObjectErr, "Recursive object found: #{obj}"
    end

    cache[obj.object_id] = true
    result = []

    obj.instance_variables.each do |var|
      result << [
        recursively_convert(var, cache),
        recursively_convert(obj.instance_variable_get(var), cache),
      ]
    end

    result
  end
end