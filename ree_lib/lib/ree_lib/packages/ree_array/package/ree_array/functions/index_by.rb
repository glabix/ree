# frozen_string_literal: true

class ReeArray::IndexBy
  include Ree::FnDSL

  fn :index_by

  contract(Or[ArrayOf[Any], Enumerable], Block => Hash)
  def call(list, &proc)
    result = {}
    list.each { result[yield(_1)] = _1 }
    result
  end
end