# frozen_string_literal: true

module ReeDto::DSL
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

    contract(Block => nil)
    def dto(&block)
      @fields ||= {}

      yield if block_given?

      init_contract_args = @fields.map {|k, opts| [k, opts[:contract_class]] }.to_h

      class_eval %Q(
        contract Kwargs[**init_contract_args] => Any
        def initialize(#{@fields.map {|k, opts| opts.key?(:default) ? "#{k}: #{opts[:init_value]}" : "#{k}:"}.join(',')})
          #{
            @fields.map {|k, _opts|
              "@#{k} = #{k}"
            }.join("\n")
          }
        end

        contract Any => Bool
        def ==(val)
          return false unless val.is_a?(self.class)

          #{
            @fields.map {|k, _|
              "@#{k} == val.#{k}"
            }.join(" && ")
          }
        end

        def to_h
          {
            #{@fields.map {|k, _| "#{k}: #{k}" }.join(", ")}
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
                @fields.map {|k, v|
                  "#{k}: other_dto.#{k}"
                }.join(",")
              }
            )
          end
        end
      )

      nil
    end

    contract(Symbol, Any, Ksplat[default?: Any, getter?: Bool, setter?: Bool] => nil)
    def field(name, contract_class, **opts)
      add_field(name, contract_class, opts)

      if opts.fetch(:getter, true)
        class_eval %Q(
          contract None => #{contract_class}
          def #{name}
            @#{name}
          end
        )
      end

      if opts.fetch(:setter, true)
        class_eval %Q(
          contract #{contract_class} => nil
          def #{name}=(val)
            @#{name}=val
            nil
          end
        )
      end

      nil
    end

    private

    def add_field(name, contract_class, opts)
      @fields[name] = opts.merge(
        contract_class: contract_class,
        init_value:     opts.key?(:default) && opts[:default].nil? ? "nil" : opts[:default]
      )
    end
  end
end