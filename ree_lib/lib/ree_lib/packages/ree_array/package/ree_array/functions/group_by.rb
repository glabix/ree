# frozen_string_literal: true

class ReeArray::GroupBy
  include Ree::FnDSL

  fn :group_by

  contract(
    ArrayOf[Any], Block => HashOf[Any, ArrayOf[Any]]
  )
  def call(list, &proc)
    result = {}

    list.each do |element|
      key = yield(element)

      if result.has_key?(key)
        result[key] << element
      else
        result[key] = [element]
      end
    end

    result
  end
end