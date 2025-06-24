# frozen_string_literal: true

class ReeString::Pluralize
  include Ree::FnDSL

  fn :pluralize

  contract(Integer, String, String, Bool => String)
  def call(count, single, plural, prefixed = true)
    word = count == 1 ? single : plural
    return word if !prefixed

    "#{count} #{word}"
  end
end
