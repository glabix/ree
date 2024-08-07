# frozen_string_literal: true

class ReeMapper::ReeDtoOutput < ReeMapper::StrategyOutput
  contract(None => Any)
  def build_object
    dto.new
  end

  contract(Object, ReeMapper::Field, Any => nil)
  def assign_value(object, field, value)
    object.set_attr(field.name, value)
    nil
  end
end