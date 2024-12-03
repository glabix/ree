# frozen_string_literal: true

class ReeArray::Wrap
  include Ree::FnDSL

  fn :wrap

  doc(<<~DOC)
    Wraps its argument in an array unless it is already an array (or array-like).

    Specifically:

    * If the argument is +nil+ an empty array is returned.
    * Otherwise, if the argument responds to +to_ary+ it is invoked, and its result returned.
    * Otherwise, returns an array with the argument as its single element.

        wrap(nil)       # => []
        wrap([1, 2, 3]) # => [1, 2, 3]
        wrap(0)         # => [0]
  DOC
  contract(Any => ArrayOf[Any])
  def call(object)
    if object.nil?
      []
    elsif object.is_a?(Array) || object.is_a?(Enumerable)
      object
    else
      [object]
    end
  end
end