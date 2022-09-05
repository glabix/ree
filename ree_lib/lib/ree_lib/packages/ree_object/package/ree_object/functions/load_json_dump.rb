# frozen_string_literal: true

class ReeObject::LoadJsonDump
  include Ree::FnDSL

  fn :load_json_dump

  ARRAY = 'array'
  HASH = 'hash'
  PRIMITIVE = 'primitive'
  OBJECT = 'object'

  contract(Hash => Any)
  def call(dump)
    recursively_load(dump)
  end

  private

  def recursively_load(dump)
    case dump['type']
    when ARRAY
      dump['value'].map { recursively_load(_1)}
    when HASH
      result = {}

      dump['value'].map do |v|
        result[recursively_load(v[0])] = recursively_load(v[1])
      end

      result
    when PRIMITIVE
      load_primitive(dump['class'], dump['value'])
    when OBJECT
      load_object(dump['class'], dump['value'])
    else
      raise NotImplementedError, "unsupported type provider '#{dump['type']}'"
    end
  end

  private

  def load_primitive(class_str, val)
    if class_str == 'Class' || class_str == 'Module'
      return Object.const_get(val)
    end

    klass = Object.const_get(class_str)

    if klass == Symbol
      val.to_sym
    elsif klass == Date
      Date.parse(val)
    elsif klass == Time
      Time.parse(val)
    elsif klass == DateTime
      DateTime.parse(val)
    elsif klass == Module || klass == Class
      klass
    else
      val
    end
  end

  def load_object(class_str, val)
    klass = Object.const_get(class_str)
    obj = klass.allocate

    val.each do |v|
      var = recursively_load(v[0])
      value = recursively_load(v[1])
      obj.instance_variable_set(var, value)
    end

    obj
  end
end