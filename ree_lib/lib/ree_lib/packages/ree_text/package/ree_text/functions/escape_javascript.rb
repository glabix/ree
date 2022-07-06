# frozen_string_literal: true

class ReeText::EscapeJavascript
  include Ree::FnDSL

  fn :escape_javascript do
    link :is_blank, from: :ree_object
    link 'ree_text/functions/constants', -> { JS_ESCAPE_MAP }
  end

  doc("Escapes carriage returns and single and double quotes for JavaScript segments.")
  contract(Nilor[String, Bool, Integer, Symbol] => String)
  def call(javascript)
    javascript = javascript.to_s

    if is_blank(javascript)
      ""
    else
      javascript.gsub(/(\\|<\/|\r\n|\342\200\250|\342\200\251|[\n\r"']|[`]|[$])/u, JS_ESCAPE_MAP)
    end
  end
end