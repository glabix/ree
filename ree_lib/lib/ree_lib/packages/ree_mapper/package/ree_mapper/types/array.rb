# frozen_string_literal: true

class ReeMapper::Array < ReeMapper::AbstractType
  attr_reader :of

  contract ReeMapper::Field => Any
  def initialize(of)
    @of = of
  end

  contract(Any, Kwargs[role: Nilor[Symbol, ArrayOf[Symbol]]] => Array).throws(ReeMapper::TypeError)
  def serialize(value, role: nil)
    if value.is_a?(Array)
      value.map {
        if _1.nil? && of.null
          _1
        else
          of.type.serialize(_1, role: role)
        end
      }
    else
      raise ReeMapper::TypeError, 'should be an array'
    end
  end

  contract(Any, Kwargs[role: Nilor[Symbol, ArrayOf[Symbol]]] => Array).throws(ReeMapper::TypeError)
  def cast(value, role: nil)
    if value.is_a?(Array)
      value.map {
        if _1.nil? && of.null
          _1
        else
          of.type.cast(_1, role: role)
        end
      }
    else
      raise ReeMapper::TypeError, "should be an array"
    end
  end

  contract(Any, Kwargs[role: Nilor[Symbol, ArrayOf[Symbol]]] => Array).throws(ReeMapper::TypeError)
  def db_dump(value, role: nil)
    if value.is_a?(Array)
      value.map {
        if _1.nil? && of.null
          _1
        else
          of.type.db_dump(_1, role: role)
        end
      }
    else
      raise ReeMapper::TypeError, 'should be an array'
    end
  end

  contract(Any, Kwargs[role: Nilor[Symbol, ArrayOf[Symbol]]] => Array).throws(ReeMapper::TypeError)
  def db_load(value, role: nil)
    if value.is_a?(Array)
      value.map {
        if _1.nil? && of.null
          _1
        else
          of.type.db_load(_1, role: role)
        end
      }
    else
      raise ReeMapper::TypeError, "should be an array"
    end
  end
end
