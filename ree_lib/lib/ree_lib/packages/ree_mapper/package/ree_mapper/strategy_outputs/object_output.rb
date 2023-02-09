# frozen_string_literal: true

class ReeMapper::ObjectOutput < ReeMapper::StrategyOutput
  contract(None => Object)
  def build_object
    dto.allocate
  end

  contract(Object, ReeMapper::Field, Any => nil)
  def assign_value(object, field, value)
    object.instance_variable_set(field.name_as_instance_var_name, value)
    nil
  end
end
