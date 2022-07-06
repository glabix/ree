# frozen_string_literal: true

class ReeObject::ToObj
  include Ree::FnDSL

  fn :to_obj do
    link :is_blank
    link :to_hash
    link 'ree_object/functions/to_hash', -> { BASIC_TYPES }
  end

  contract(Any => Or[Object, ArrayOf[Object], *BASIC_TYPES])
  def call(obj)
    dump = to_hash(obj)
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
end