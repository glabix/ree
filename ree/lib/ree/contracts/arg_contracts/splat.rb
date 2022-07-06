# frozen_string_literal: true

require 'set'

module Ree::Contracts
  module ArgContracts
    class Splat
      include Ree::Contracts::Truncatable

      def self.[](*contracts)
        if contracts.empty?
          raise BadContractError, 'Splat contract should accept at least one contract'
        end

        forbidden_class_contracts = Ree::Contracts::Validators::FORBIDDEN_CONTRACTS
        forbidden = Set.new(forbidden_class_contracts.to_a - [ArgContracts::SplatOf])
        
        contracts.each_with_index do |contract, index|
          contract_name = if forbidden_class_contracts.include?(contract)
            contract.to_s
          elsif forbidden.include?(contract.class)
            contract.class.to_s
          end

          if contract_name
            raise BadContractError, "#{contract_name} contract is not allowed to use inside Splat contract"
          end
        end

        splat_of_count = contracts.count { _1.is_a?(ArgContracts::SplatOf) }

        if splat_of_count != 1
          raise BadContractError, "Splat contract should include one SplatOf contract"
        end

        new(contracts)
      end

      def initialize(contracts)
        @contracts = contracts

        @first_splat_of = contracts.first.is_a?(ArgContracts::SplatOf) ? contracts.first : nil
        @last_splat_of = contracts.size > 1 && contracts.last.is_a?(ArgContracts::SplatOf) ? contracts.last : nil

        @middle_splat_of = if contracts.size > 2
          list = contracts[1..-2]
          idx = list.index { _1.is_a?(ArgContracts::SplatOf) }
          list[idx] if idx
        end

        @middle_splat_of_index = @contracts.index { _1 == @middle_splat_of } if @middle_splat_of
        @validators = contracts.map { Validators.fetch_for(_1) }
      end

      def valid?(value)
        return false if !value.is_a?(Array)
        return false if @validators.size - 1 > value.size
        
        if @first_splat_of
          return valid_with_first?(@validators, value)
        end

        if @last_splat_of
          return valid_with_last?(@validators, value)
        end

        if @middle_splat_of
          # before splat part
          left_contract_count = @middle_splat_of_index
          right_contract_count = @validators.size - @middle_splat_of_index - 1

          is_valid = value[0..left_contract_count - 1].each_with_index.all? do |value, idx|
            @validators[idx].call(value)
          end

          return false if !is_valid

          # splat part
          splat_values = if left_contract_count + right_contract_count == value.size
            []
          else
            value[@middle_splat_of_index..value.size - right_contract_count - 1]
          end
          
          if !splat_values.empty?
            return false if !@validators[@middle_splat_of_index].call(splat_values)
          end

          # after splat part
          is_valid = value[value.size - right_contract_count..-1].each_with_index.all? do |value, idx|
            @validators[@middle_splat_of_index + idx + 1].call(value)
          end

          return false if !is_valid
        end

        return true
      end

      def to_s
        "Splat[#{@validators.map(&:to_s).join(", ")}]"
      end

      def message(value, name, lvl = 1)
        unless value.is_a?(Array)
          return "expected #{to_s}, got #{value.class} => #{truncate(value.inspect)}"
        end

        errors = []
        sps = "  " * lvl
        
        if @validators.size - 1 > value.size
          return "expected at least #{@validators.size - 1} #{pluralize(@validators.size, 'value', 'values')} for #{to_s}, got #{value.size} #{pluralize(value.size, 'value', 'values')} => #{truncate(value.inspect)}"
        end
        
        if @first_splat_of
          rest_validators = @validators[1..-1]
          rest_validator_count = rest_validators.size

          rest_values = if value.size >= @validators.size
            value[(value.size - rest_validator_count)..-1]
          else
            value
          end

          if rest_validator_count > 0
            rest_validators.each_with_index do |validator, idx|
              val = rest_values[idx]
              next if validator.call(val)
              
              msg = validator.message(val, "#{name}[#{idx + 1}]", lvl + 1)
              errors << "\n\t#{sps} - #{name}[#{idx + 1}]: #{msg}"

              if errors.size > 3
                errors << "\n\t#{sps} - ..."
                break
              end
            end
          end

          if rest_values.size != value.size
            validator = @validators.first
            idx = value.size - rest_validator_count - 1
            val = value[0..idx]

            if !validator.call(val)
              msg = validator.message(val, "#{name}[0..#{idx}]", lvl + 1)
              errors << "\n\t#{sps} - #{name}[0..#{idx}]: #{msg}"
            end
          end
        elsif @last_splat_of
          rest_validators = @validators[0..-2]
          rest_validator_count = rest_validators.size

          rest_values = if value.size >= @validators.size
            value[0..-2]
          else
            value
          end

          if rest_validator_count > 0
            rest_validators.each_with_index do |validator, idx|
              val = rest_values[idx]
              next if validator.call(val)

              msg = validator.message(val, "#{name}[#{idx}]", lvl + 1)
              errors << "\n\t#{sps} - #{name}[#{idx}]: #{msg}"

              if errors.size > 3
                errors << "\n\t#{sps} - ..."
                break
              end
            end
          end

          if rest_values.size != value.size
            validator = @validators.last
            idx = rest_validator_count
            val = value[idx..-1]

            if !validator.call(val)
              msg = validator.message(val, "#{name}[#{idx}..#{value.size - 1}]", lvl + 1)
              errors << "\n\t#{sps} - #{name}[#{idx}..#{value.size - 1}]: #{msg}"
            end
          end
        elsif @middle_splat_of
          left_contract_count = @middle_splat_of_index
          right_contract_count = @validators.size - @middle_splat_of_index - 1

          value[0..left_contract_count - 1].each_with_index do |value, idx|
            validator = @validators[idx]
            next if validator.call(value)

            msg = validator.message(value, "#{name}[#{idx}]", lvl + 1)
            errors << "\n\t#{sps} - #{name}[#{idx}]: #{msg}"

            if errors.size > 3
              errors << "\n\t#{sps} - ..."
              break
            end
          end

          splat_values = if left_contract_count + right_contract_count == value.size
            []
          else
            value[@middle_splat_of_index..value.size - right_contract_count - 1]
          end
          
          if !splat_values.empty?
            validator = @validators[@middle_splat_of_index]

            if !validator.call(splat_values)
              splat_name = "#{name}[#{@middle_splat_of_index}..#{value.size - right_contract_count - 1}]"
              msg = validator.message(splat_values, "#{splat_name}", lvl + 1)
              errors << "\n\t#{sps} - #{splat_name}: #{msg}"
            end
          end

          is_valid = value[value.size - right_contract_count..-1].each_with_index.all? do |value, idx|
            @validators[@middle_splat_of_index + idx + 1].call(value)
          end

          pos = value.size - right_contract_count
          
          value[pos..-1].each_with_index do |value, idx|
            validator = @validators[@middle_splat_of_index + idx + 1]
            next if validator.call(value)

            msg = validator.message(value, "#{name}[#{pos + idx}]", lvl + 1)
            errors << "\n\t#{sps} - #{name}[#{pos + idx}]: #{msg}"

            if errors.size > 3
              errors << "\n\t#{sps} - ..."
              break
            end
          end
        end

        errors.join
      end

      private

      def valid_with_first?(validators, values)
        rest_validators = validators[1..-1]
        rest_validator_count = rest_validators.size

        rest_values = if values.size >= validators.size
          values[(values.size - rest_validator_count)..-1]
        else
          values
        end

        has_error = false

        if rest_validator_count > 0
          has_error = rest_validators.each_with_index.any? do |validator, idx|
            !validator.call(rest_values[idx])
          end
        end

        return false if has_error
        return true if rest_values.size == values.size

        validators.first.call(values[0..(values.size - rest_validator_count - 1)])
      end

      def valid_with_last?(validators, values)
        rest_validators = validators[0..-2]
        rest_validator_count = rest_validators.size
        
        rest_values = if values.size >= validators.size
          values[0..-2]
        else
          values
        end

        has_error = false

        if rest_validator_count > 0
          has_error = rest_validators.each_with_index.any? do |validator, idx|
            !validator.call(rest_values[idx])
          end
        end

        return false if has_error
        return true if rest_values.size == values.size

        validators.last.call(values[rest_validator_count..-1])
      end

      def pluralize(num, single, plural)
        num == 1 ? single : plural
      end
    end
  end
end
