# frozen_string_literal: true

class ReeString::Pluralize
  include Ree::FnDSL

  fn :pluralize

  contract(Integer, String, String => String)
  def call(count, single, plural)
    word = count == 1 ? single : plural
    "#{count} #{word}"
  end
end