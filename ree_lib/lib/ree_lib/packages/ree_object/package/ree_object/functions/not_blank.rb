# frozen_string_literal: true

class ReeObject::NotBlank
  include Ree::FnDSL

  fn :not_blank do
    link :is_blank
  end

  doc("Opposite to is_blank")
  contract(Any => Bool)
  def call(obj)
    !is_blank(obj)
  end
end