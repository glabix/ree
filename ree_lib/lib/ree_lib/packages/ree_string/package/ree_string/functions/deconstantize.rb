# frozen_string_literal: true

class ReeString::Deconstantize
  include Ree::FnDSL

  fn :deconstantize

  doc(<<~DOC)
    Removes the rightmost segment from the constant expression in the string.

      deconstantize('Net::HTTP')   # => "Net"
      deconstantize('::Net::HTTP') # => "::Net"
      deconstantize('String')      # => ""
      deconstantize('::String')    # => ""
      deconstantize('')            # => ""
  DOC
  contract(String => String)
  def call(path)
    path.to_s[0, path.rindex("::") || 0]
  end
end