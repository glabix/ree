# frozen_string_literal: true

class ReeMapper::StrategyOutput
  attr_reader :dto

  contract(Class => Any)
  def initialize(dto)
    @dto = dto
  end

  contract(Object, ReeMapper::Field, Any => nil).throws(NotImplementedError)
  def assign_value(object, field, value)
    raise NotImplementedError
  end

  contract(ArrayOf[Symbol] => nil)
  def prepare_dto(field_names); end
end
