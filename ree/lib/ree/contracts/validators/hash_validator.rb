# frozen_string_literal: true

require 'set'

module Ree::Contracts
  class HashValidator < BaseValidator
    attr_reader :opt_dict, :validators

    def initialize(contract)
      super(contract)

      @opt_dict = Set.new

      @validators = contract
        .transform_values { |cont| Validators.fetch_for(cont) }
        .transform_keys { |key|
          next key unless key.is_a?(String) || key.is_a?(Symbol)

          key_str = key.to_s
          next key unless key_str.end_with?('?') && key_str.length > 1

          opt_key = key_str[0..-2]
          opt_key = opt_key.to_sym if key.is_a? Symbol
          @opt_dict << opt_key

          opt_key
        }
    end

    def call(value)
      return false unless value.is_a?(Hash)
      return false unless value.all? { |key, _| validators.has_key?(key) }

      validators.all? do |key, validator|
        value.has_key?(key) ? validator.call(value[key]) : optional?(key)
      end
    end

    def to_s
      "{#{validators.map { |k, v| "#{key_to_s(k)} => #{v.to_s}" }.join(', ')}}"
    end

    def message(value, name, lvl = 1)
      unless value.is_a?(Hash)
        return "expected Hash, got #{value.class} => #{truncate(value.inspect)}"
      end

      errors = []
      sps = "  " * lvl

      validators.each do |key, validator|
        if errors.size > 3
          errors << "\n\t#{sps} - ..."
          break
        end

        unless value.key?(key)
          errors << "\n\t#{sps} - #{name}[#{key.inspect}]: missing" unless optional?(key)
          next
        end

        val = value[key]
        next if validator.call(val)

        msg = validator.message(val, "#{name}[#{key.inspect}]", lvl + 1)
        errors << "\n\t#{sps} - #{name}[#{key.inspect}]: #{msg}"
      end

      value.each do |key, val|
        if errors.size > 3
          errors << "\n\t#{sps} - ..."
          break
        end

        next if validators.key?(key)

        errors << "\n\t#{sps} - #{name}[#{key.inspect}]: unexpected"
      end

      errors.join
    end

    private

    def key_to_s(key)
      k =if optional?(key)
        v = "#{key}?"
        key.is_a?(String) ? v : v.to_sym
      else
        key
      end

      k.inspect
    end

    def optional?(key)
      opt_dict.include?(key)
    end
  end
end
