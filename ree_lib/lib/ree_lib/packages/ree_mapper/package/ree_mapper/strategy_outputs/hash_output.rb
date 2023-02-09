# frozen_string_literal: true

class ReeMapper::HashOutput < ReeMapper::StrategyOutput
  contract(None => Object)
  def build_object
    dto.new
  end

  contract(Object, ReeMapper::Field, Any => nil)
  def assign_value(object, field, value)
    object[field.name] = value
    nil
  end
end