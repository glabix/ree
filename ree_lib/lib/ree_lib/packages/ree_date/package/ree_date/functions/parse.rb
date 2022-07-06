# frozen_string_literal: true

class ReeDate::Parse
  include Ree::FnDSL

  fn :parse

  doc("Converts a string to a date")
  contract(String => Date).throws(ArgumentError)
  def call(string)
    Date.parse(string)
  end
end