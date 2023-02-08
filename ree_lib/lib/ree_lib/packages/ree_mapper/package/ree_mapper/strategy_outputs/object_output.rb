# frozen_string_literal: true

class ReeMapper::ObjectOutput < ReeMapper::StrategyOutput
  contract(ArrayOf[Symbol] => Object)
  def build_object(_field_names)
    dto.allocate
  end

  contract(Object, ReeMapper::Field, Any => nil)
  def assign_value(object, field, value)
    object.instance_variable_set(field.name_as_instance_var_name, value)
    nil
  end
end
