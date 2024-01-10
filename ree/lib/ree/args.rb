# frozen_string_literal: true

module Ree::Args
  def check_arg(value, name, klass)
    if !value.is_a?(klass)
      raise Ree::Error.new(
        ":#{name} should be a #{klass}. Got #{value.class}: #{Ree::StringUtils.truncate(value.inspect)}",
        :invalid_arg
      )
    end
  end

  def check_bool(value, name)
    check_arg_any(value, name, [TrueClass, FalseClass])
  end

  def check_arg_array_of(value, name, klass)
    if !value.is_a?(Array) && value.detect { |_| !_.is_a?(Symbol)}
      raise Ree::Error.new(":#{name} should be array of #{klass.inspect}. Got #{value.class}: #{Ree::StringUtils.truncate(value.inspect)}", :invalid_arg)
    end
  end

  def check_arg_any(value, name, klasses)
    if !klasses.detect {|klass| value.is_a?(klass)}
      raise Ree::Error.new(":#{name} should be any of #{klasses.inspect}", :invalid_arg)
    end
  end

  def not_nil(value, name)
    if value.nil?
      raise Ree::Error(":#{name} should not be nil", :invalid_arg)
    end
  end
end