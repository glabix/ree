# frozen_string_literal: true

class ReeMapper::StrategyOutput
  contract(Class => Any)
  def initialize(dto)
    @dto = dto
  end

  contract(Object, ReeMapper::Field, Any => nil).throws(NotImplementedError)
  def assign_value(object, field, value)
    raise NotImplementedError
  end

  private

  attr_reader :dto
end
