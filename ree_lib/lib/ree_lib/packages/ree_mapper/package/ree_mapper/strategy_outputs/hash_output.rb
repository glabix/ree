# frozen_string_literal: true

class ReeMapper::HashOutput < ReeMapper::StrategyOutput
  contract(ArrayOf[Symbol] => Object)
  def build_object(_field_names)
    dto.new
  end

  contract(Object, ReeMapper::Field, Any => nil)
  def assign_value(object, field, value)
    object[field.name] = value
    nil
  end
end