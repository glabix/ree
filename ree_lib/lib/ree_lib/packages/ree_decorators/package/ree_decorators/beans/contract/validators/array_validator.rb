# frozen_string_literal: true

module ReeDecorators::ArrayValidator
  include Ree::BeanDSL

  bean :array_validator do
    link :truncate, from: :ree_string
    link :pluralize, from: :ree_string
  end

  def validate?(validators, ary)
    return false unless ary.is_a?(Array) && ary.length == validators.length

    ary.zip(validators).all? do |el, validator|
      validator.validate?(el)
    end
  end

  def to_s(validators)
    "[#{validators.map(&:to_s).join(', ')}]"
  end

  def message(value, name, lvl = 1)
    unless value.is_a?(Array)
      return "expected Array, got #{value.class} => #{truncate(value.inspect, 80)}"
    end

    unless value.length == validators.length
      return "expected to have #{validators.length} #{pluralize(validators.length, 'item', 'items')}, got #{value.length} #{pluralize(value.length, 'item', 'items')} => #{truncate(value.inspect, 80)}"
    end

    errors = []
    sps = "  " * lvl

    value.zip(validators).each_with_index do |(val, validator), idx|
      next if validator.call(val)

      msg = validator.message(val, "#{name}[#{idx}]", lvl + 1)
      errors << "\n\t#{sps} - #{name}[#{idx}]: #{msg}"

      if errors.size > 3
        errors << "\n\t#{sps} - ..."
        break
      end
    end

    errors.join
  end
end
