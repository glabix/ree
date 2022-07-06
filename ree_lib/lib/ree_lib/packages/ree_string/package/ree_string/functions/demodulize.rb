# frozen_string_literal: true

class ReeString::Demodulize
  include Ree::FnDSL

  fn :demodulize

  doc(<<~DOC)
    Removes the module part from the expression in the string.
    
      demodulize('ActiveSupport::Inflector::Inflections') # => "Inflections"
      demodulize('Inflections')                           # => "Inflections"
      demodulize('::Inflections')                         # => "Inflections"
      demodulize('')                                      # => ""
    
    See also #deconstantize.
  DOC
  contract(String => String)
  def call(path)
    path = path.to_s

    if i = path.rindex("::")
      path[(i + 2)..-1]
    else
      path
    end
  end
end