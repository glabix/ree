# frozen_string_literal: true

require 'cgi'

class ReeText::EscapeHtml
  include Ree::FnDSL

  fn :escape_html

  doc("A utility method for escaping HTML.")
  contract(String => String)
  def call(str)
    CGI.escapeHTML(str)
  end
end