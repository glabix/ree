# frozen_string_literal: true

class ReeMapper::MapperStrategy
  attr_reader :method, :always_optional

  contract(Symbol, Class, Bool => Any)
  def initialize(method:, dto:, always_optional:)
    @method          = method
    @output          = build_output(dto)
    @always_optional = always_optional
  end

  def initialize_dup(_orig)
    @output = @output.dup
    super
  end

  contract(None => Object)
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

  contract(Class => nil)
  def dto=(dto)
    @output = build_output(dto)
    nil
  end

  contract(None => Class)
  def dto
    output.dto
  end

  contract(ArrayOf[Symbol] => nil)
  def prepare_dto(field_names)
    output.prepare_dto(field_names)
  end

  private

  attr_reader :output

  def build_output(dto)
    if dto == Hash || (defined?(OpenStruct) && dto == OpenStruct)
      ReeMapper::HashOutput.new(dto)
    elsif dto == Struct
      ReeMapper::StructOutput.new
    else
      ReeMapper::ObjectOutput.new(dto)
    end
  end
end
