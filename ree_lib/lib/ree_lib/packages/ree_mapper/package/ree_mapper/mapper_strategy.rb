# frozen_string_literal: true

class ReeMapper::MapperStrategy
  attr_reader :method, :always_optional

  contract(Symbol, ReeMapper::StrategyOutput, Bool => Any)
  def initialize(method:, output:, always_optional:)
    @method          = method
    @output          = output
    @always_optional = always_optional
  end

  contract None => ReeMapper::StrategyOutput
  def output
    @output
  end

  contract ReeMapper::StrategyOutput => ReeMapper::StrategyOutput
  def output=(output)
    @output = output
  end

  contract(Any)
  def build_object
    output.build_object
  end

  contract(Any, ReeMapper::Field, Any => nil)
  def assign_value(object, field, value)
    output.assign_value(object, field, value)
  end

  contract(Any, ReeMapper::Field => Bool)
  def has_value?(obj, field)
    if obj.is_a?(Hash)
      obj.key?(field.from) || obj.key?(field.from_as_str)
    else
      obj.respond_to?(field.from)
    end
  end

  contract(Any, ReeMapper::Field => Any)
  def get_value(obj, field)
    if obj.is_a?(Hash)
      obj.key?(field.from) ? obj[field.from] : obj[field.from_as_str]
    else
      obj.public_send(field.from)
    end
  end

  contract(Class => Class)
  def dto=(dto)
    output.dto = dto
  end

  contract(None => Nilor[Class])
  def dto
    output.dto
  end
end
