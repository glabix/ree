# frozen_string_literal: true

class ReeText::SanitizeCss
  include Ree::FnDSL

  fn :sanitize_css

  doc("Sanitizes a block of CSS code")
  contract(String => String)
  def call(str)
    Loofah::HTML5::Scrub.scrub_css(str)
  end
end