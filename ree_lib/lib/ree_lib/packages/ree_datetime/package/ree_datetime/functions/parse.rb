# frozen_string_literal: true

class ReeDatetime::Parse
  include Ree::FnDSL

  fn :parse

  doc("Converts a string to a date/time")
  contract(String => DateTime).throws(ArgumentError)
  def call(string)
    DateTime.parse(string)
  end
end