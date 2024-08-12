# frozen_string_literal: true

class ReeArray::SplitBy
  include Ree::FnDSL

  fn :split_by

  doc(<<~DOC)
    Divides the array into one or more subarrays based on a delimiting +value+
    or the result of an optional block.

    split([1, 2, 3, 4, 5], 3)              # => [[1, 2], [4, 5]]
    split((1..10).to_a) { |i| i % 3 == 0 } # => [[1, 2], [4, 5], [7, 8], [10]]
  DOC
  contract(Or[ArrayOf[Any], Enumerable], Any, Optblock => ArrayOf[Any])
  def call(array, value = nil, &block)
    arr = array.dup
    result = []

    if block_given?
      while (idx = arr.index(&block))
        result << arr.shift(idx)
        arr.shift
      end
    else
      while (idx = arr.index(value))
        result << arr.shift(idx)
        arr.shift
      end
    end

    result << arr
  end
end