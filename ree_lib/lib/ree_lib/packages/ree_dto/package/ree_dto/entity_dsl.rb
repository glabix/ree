# frozen_string_literal: true

module ReeDto::EntityDSL
  def self.included(base)
    base.include(InstanceMethods)
    base.extend(ClassMethods)
  end

  def self.extended(base)
    base.include(InstanceMethods)
    base.extend(ClassMethods)
  end

  module InstanceMethods
    def to_s
      variables = self
        .instance_variables
        .map(&:to_s)
        .map { |v| v.gsub('@', '') }
        .sort

      max_length = variables.sort_by(&:size).last.size
      result     = "\n#{self.class}\n"

      result << variables
        .map { |variable|
          name = variable.to_s
          extra_spaces = ' ' * (max_length - name.size)
          %Q(  #{name}#{extra_spaces} = #{instance_variable_get("@#{variable}")})
        }
        .join("\n")

      result
    end

    def inspect
      to_s
    end
  end

  module ClassMethods
    include Ree::Contracts::Core
    include Ree::Contracts::ArgContracts

    PropertyNotSetError = Class.new(StandardError)

    contract(Ksplat[RestKeys => Any] => nil)
    def properties(**args)
      args.each do |name, contract_class|
        contract None => contract_class
        class_eval %Q(
          def #{name}
            @#{name}
          end
        )
      end

      contract Kwargs[**args] => Any
      class_eval %Q(
        def initialize(#{args.keys.map {|k| "#{k}: nil"}.join(',')})
          #{
            args.map {|k, v|
              "@#{k} = #{k}"
            }.join("\n")
          }
        end

        contract Any => Bool
        def ==(val)
          return false unless val.is_a?(self.class)

          #{
            args.map {|k, _|
              "@#{k} == val.#{k}"
            }.join(" && ")
          }
        end

        def to_h
          {
            #{args.map {|k, _| "#{k}: #{k}" }.join(", ")}
          }
        end

        def values_for(*args)
          args.map do |arg|
            variable = ("@" + arg.to_s).to_sym

            if !instance_variables.include?(variable)
              raise ArgumentError.new("variable :" + arg.to_s + " not found in dto")
            end

            instance_variable_get(variable)
          end
        end

        class << self
          def import_from(other_dto)
            self.new(
              #{
                args.map {|k, v|
                  "#{k}: other_dto.#{k}"
                }.join(",")
              }
            )
          end
        end
      )

      nil
    end

    contract(Symbol, Any => nil).throws(PropertyNotSetError)
    def collection(collection_name, contract_class)
      define_method collection_name.to_s do
        value = instance_variable_get("@#{collection_name}")
        raise PropertyNotSetError.new if !value

        value
      end

      define_method "set_#{collection_name.to_s}" do |list|
        instance_variable_set("@#{collection_name}", list); nil
      end

      nil
    end
  end
end