# frozen_string_literal: true

class ReeHash::TransformValues
  include Ree::FnDSL

  fn :transform_values

  doc("Transforms values with passed parameter (block). By default transforms deeply")
  contract(Hash, Kwargs[deep: Bool], Block => Hash)
  def call(hash, deep: true, &proc)
    recursively_transform_values(nil, hash, deep, &proc)
  end

  private

  def recursively_transform_values(parent_key, object, deep, &block)
    case object
    when Hash
      result = {}

      result.default = object.default
      result.default_proc = object.default_proc if object.default_proc

      object.each do |key, value|
        result[key] = if deep
          yield(
            key, recursively_transform_values(key, value, deep, &block)
          )
        else
          yield(key, value)
        end
      end

      result
    when Array
      if deep
        object.map do
          yield(
            parent_key, recursively_transform_values(
              parent_key, _1, deep, &block
            )
          )
        end
      else
        yield(parent_key, object)
      end
    else
      yield(parent_key, object)
    end
  end
end