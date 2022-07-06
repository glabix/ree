# frozen_string_literal: true

class ReeMapper::StrategyOutput
  def build_object
    raise NotImplementedError
  end

  def assign_value(*)
    raise NotImplementedError
  end

  contract(Class => Class)
  def dto=(dto)
    @dto = dto
  end

  contract(None => Nilor[Class])
  def dto
    @dto
  end
end
