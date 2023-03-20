# frozen_string_literal: true

class ReeMapper::Array < ReeMapper::AbstractWrapper
  contract(Any, Kwargs[name: String, role: Nilor[Symbol, ArrayOf[Symbol]], fields_filters: ArrayOf[ReeMapper::FieldsFilter]] => Array)
    .throws(ReeMapper::TypeError)
  def serialize(value, name:, role: nil, fields_filters: [])
    if value.is_a?(Array)
      value.map.with_index {
        if _1.nil? && subject.null
          _1
        else
          subject.type.serialize(_1, name: "#{name}[#{_2}]", role: role, fields_filters: fields_filters + [subject.fields_filter])
        end
      }
    else
      raise ReeMapper::TypeError, "`#{name}` should be an array"
    end
  end

  contract(Any, Kwargs[name: String, role: Nilor[Symbol, ArrayOf[Symbol]], fields_filters: ArrayOf[ReeMapper::FieldsFilter]] => Array)
    .throws(ReeMapper::TypeError)
  def cast(value, name:, role: nil, fields_filters: [])
    if value.is_a?(Array)
      value.map.with_index {
        if _1.nil? && subject.null
          _1
        else
          subject.type.cast(_1, name: "#{name}[#{_2}]", role: role, fields_filters: fields_filters + [subject.fields_filter])
        end
      }
    else
      raise ReeMapper::TypeError, "`#{name}` should be an array"
    end
  end

  contract(Any, Kwargs[name: String, role: Nilor[Symbol, ArrayOf[Symbol]], fields_filters: ArrayOf[ReeMapper::FieldsFilter]] => Array)
    .throws(ReeMapper::TypeError)
  def db_dump(value, name:, role: nil, fields_filters: [])
    if value.is_a?(Array)
      value.map.with_index {
        if _1.nil? && subject.null
          _1
        else
          subject.type.db_dump(_1, name: "#{name}[#{_2}]", role: role, fields_filters: fields_filters + [subject.fields_filter])
        end
      }
    else
      raise ReeMapper::TypeError, "`#{name}` should be an array"
    end
  end

  contract(Any, Kwargs[name: String, role: Nilor[Symbol, ArrayOf[Symbol]], fields_filters: ArrayOf[ReeMapper::FieldsFilter]] => Array)
    .throws(ReeMapper::TypeError)
  def db_load(value, name:, role: nil, fields_filters: [])
    if value.is_a?(Array)
      value.map.with_index {
        if _1.nil? && subject.null
          _1
        else
          subject.type.db_load(_1, name: "#{name}[#{_2}]", role: role, fields_filters: fields_filters + [subject.fields_filter])
        end
      }
    else
      raise ReeMapper::TypeError, "`#{name}` should be an array"
    end
  end
end