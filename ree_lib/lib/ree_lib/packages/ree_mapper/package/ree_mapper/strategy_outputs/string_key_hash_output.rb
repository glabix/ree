# frozen_string_literal: true

class ReeMapper::StringKeyHashOutput < ReeMapper::StrategyOutput
  contract(Hash)
  def build_object
    Hash.new
  end

  contract(Object, ReeMapper::Field, Any => nil)
  def assign_value(object, field, value)
    object[field.name_as_str] = value
    nil
  end
end
