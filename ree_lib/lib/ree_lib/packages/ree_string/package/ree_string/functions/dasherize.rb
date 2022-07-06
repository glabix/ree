# frozen_string_literal: true

class ReeString::Dasherize
  include Ree::FnDSL

  fn :dasherize

  doc(<<~DOC)
    Replaces underscores with dashes in the string.
    
      dasherize('puni_puni') # => "puni-puni"
  DOC
  contract(String => String)
  def call(underscored_word)
    underscored_word.tr("_", "-")
  end
end