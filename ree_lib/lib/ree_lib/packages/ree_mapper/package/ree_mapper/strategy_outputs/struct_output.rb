# frozen_string_literal: true

class ReeMapper::StructOutput < ReeMapper::StrategyOutput
  contract(None => Any)
  def initialize; end

  contract(ArrayOf[Symbol] => Object)
  def build_object(field_names)
    @dto ||= begin
      field_names = [:_] if field_names.empty?
      Struct.new(*field_names)
    end
    dto.allocate
  end

  contract(Object, ReeMapper::Field, Any => nil)
  def assign_value(object, field, value)
    object[field.name] = value
    nil
  end
end