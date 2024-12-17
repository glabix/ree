# frozen_string_literal: true

class StringUtils::DoNothing
  include Ree::FnDSL

  fn :do_nothing

  contract(String => String)
  def call(str)
    str
  end
end