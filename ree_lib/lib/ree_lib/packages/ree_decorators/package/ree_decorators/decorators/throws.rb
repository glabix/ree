# frozen_string_literal: true

class ReeDecorators::Throws
  include ReeDecorators::DSL

  decorator :throws

  def build_context(*exception_classes)
    exception_classes
  end
end
