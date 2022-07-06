# frozen_string_literal: true

require 'set'

module Ree::Contracts
  module ArgContracts
    class RestKeys; end

    class Ksplat
      include Ree::Contracts::Truncatable

      attr_reader :validators, :rest_validator
      
      def self.[](**contracts)
        if contracts.empty?
          raise BadContractError, 'Ksplat contract should accept at least one contract'
        end

        new(**contracts)
      end

      def initialize(**contracts)
        @contracts = contracts
        @opt_dict = Set.new

        @validators = contracts
          .transform_values { Validators.fetch_for(_1) }
          .transform_keys { |key|
            next key unless key.is_a?(String) || key.is_a?(Symbol)

            key_str = key.to_s
            next key unless key_str.end_with?('?') && key_str.length > 1

            opt_key = key_str[0..-2]
            opt_key = opt_key.to_sym if key.is_a? Symbol
            @opt_dict << opt_key

            opt_key
          }
        
        @rest_validator = @validators[RestKeys]
        
        if @rest_validator
          @validators.default = @rest_validator
        end
      end

      def valid?(value)
        return false unless value.is_a?(Hash)
        return false if value.has_key?(RestKeys)
        
        is_valid = value.all? do |key, v|
          if @validators.has_key?(key)
            @validators[key].call(v)
          elsif @rest_validator
            @rest_validator.call(v)
          else
            false
          end
        end

        return false if !is_valid

        return false if @validators.detect do |key, validator|
          next if key == RestKeys || optional?(key)
          next if value.has_key?(key)
          true
        end

        true
      end

      def to_s
        "Ksplat[#{validators.map { |k, v| "#{key_to_s(k)} => #{v.to_s}" }.join(', ')}]"
      end

      def message(value, name, lvl = 1)
        unless value.is_a?(Hash)
          return "expected Hash, got #{value.class} => #{truncate(value.inspect)}"
        end

        if value.has_key?(RestKeys)
          return "RestKeys is a reserved key for Ksplat contract"
        end
  
        errors = []
        sps = "  " * lvl
        all_keys = (@validators.keys - [RestKeys] + value.keys).uniq

        all_keys.each do |key|
          validator = @validators[key]

          if !validator
            errors << "\n\t#{sps} - #{name}[#{key.inspect}]: unexpected"
            next
          end

          if !value.has_key?(key)
            if !optional?(key)
              errors << "\n\t#{sps} - #{name}[#{key.inspect}]: missing"
            else
              next
            end
          end
  
          val = value[key]
          next if validator.call(val)
  
          msg = validator.message(val, "#{name}[#{key.inspect}]", lvl + 1)
          errors << "\n\t#{sps} - #{name}[#{key.inspect}]: #{msg}"

          if errors.size > 3
            errors << "\n\t#{sps} - ..."
            break
          end
        end
  
        errors.join
      end

      private

      def key_to_s(key)
        k = if optional?(key)
          v = "#{key}?"
          key.is_a?(String) ? v : v.to_sym
        elsif key == RestKeys
          'RestKeys'
        else
          key.to_s
        end
  
        k.inspect
      end

      def optional?(key)
        @opt_dict.include?(key)
      end
    end
  end
end
