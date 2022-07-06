# frozen_string_literal: true

class ReeHash::TransformKeys
  include Ree::FnDSL

  fn :transform_keys
  
  doc("Transforms keys with passed parameter (block), deep transform is by default ")
  contract(Hash, Kwargs[deep: Bool], Block => Hash)
  def call(hash, deep: true, &proc)
    recursively_transform_keys(hash, deep, &proc)
  end

  private

  def recursively_transform_keys(object, deep, &block)
    case object
    when Hash
      result = {}

      result.default = object.default
      result.default_proc = object.default_proc if object.default_proc

      object.keys.each do |key|
        value = object[key]
        
        result[yield(key)] = if deep
          recursively_transform_keys(value, deep, &block)
        else
          value
        end
      end

      result
    when Array
      if deep
        object.map { recursively_transform_keys(_1, deep, &block) }
      else
        object
      end
    else
      object
    end
  end
end