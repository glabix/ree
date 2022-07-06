# frozen_string_literal: true

require 'cgi'

class ReeText::UnescapeHtml
  include Ree::FnDSL

  fn :unescape_html 

  doc("A utility method for unescaping HTML.")
  contract(String => String)
  def call(str)
    CGI.unescapeHTML(str)
  end
end