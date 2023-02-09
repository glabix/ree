# frozen_string_literal: true

class ReeMapper::StructOutput < ReeMapper::StrategyOutput
  contract(None => Any)
  def initialize; end

  def initialize_dup(orig)
    @dto = nil
    super
  end

  contract(None => Object)
  def build_object
    dto.allocate
  end

  contract(Object, ReeMapper::Field, Any => nil)
  def assign_value(object, field, value)
    object[field.name] = value
    nil
  end

  contract(ArrayOf[Symbol] => nil)
  def prepare_dto(field_names)
    @dto = Struct.new(*field_names)
    nil
  end
end