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
    include Ree::Contracts::Core
    include Ree::Contracts::ArgContracts

    contract Any => Bool
    def ==(val)
      return false unless val.is_a?(self.class)

      vars = val.instance_variables | self.instance_variables

      return false if vars.any? do |var|
        result = self.instance_variable_defined?(var) && val.instance_variable_defined?(var)
        result = result && (self.instance_variable_get(var) == val.instance_variable_get(var))
        !result
      end

      true
    end

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
      args.each do |property_name, contract_class|
        property(property_name, contract_class)
      end

      define_method :initialize do |**kwargs|
        kwargs.each do |name, var|
          send("#{name}=", var)
        end
      end

      nil
    end

    contract(Symbol, Any => nil).throws(PropertyNotSetError)
    def collection(collection_name, contract_class)
      if !contract_class.is_a?(Ree::Contracts::ArgContracts::ArrayOf)
        raise ArgumentError.new("collection contract class should be ArrayOf[...]")
      end

      contract(None => contract_class).throws(PropertyNotSetError)
      define_method collection_name do
        name = :"@#{collection_name}"

        if ReeDto.strict_mode?
          raise PropertyNotSetError.new if !instance_variable_defined?(name)
        end

        instance_variable_get(name)
      end

      contract(contract_class => nil)
      define_method :"set_#{collection_name}" do |list|
        instance_variable_set("@#{collection_name}", list); nil
      end

      nil
    end

    contract(Symbol, Any, Kwargs[getter: Bool, setter: Bool] => nil)
    def property(property_name, contract_class, getter: true, setter: true)
      if getter
        contract(None => contract_class).throws(PropertyNotSetError)
        define_method property_name do
          name = :"@#{property_name}"

          if ReeDto.strict_mode?
            raise PropertyNotSetError.new if !instance_variable_defined?(name)
          end

          instance_variable_get(name)
        end
      end

      if setter
        contract(contract_class => contract_class)
        define_method :"#{property_name}=" do |value|
          instance_variable_set("@#{property_name}", value)
        end
      end

      nil
    end
  end
end