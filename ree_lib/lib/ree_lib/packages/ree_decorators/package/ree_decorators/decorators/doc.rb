# frozen_string_literal: true

class ReeDecorators::Doc
  include ReeDecorators::DSL

  decorator :doc

  def build_context(str)
    str
  end
end
