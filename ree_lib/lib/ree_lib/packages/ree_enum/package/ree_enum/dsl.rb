# frozen_string_literal: true
package_require 'ree_swagger/functions/register_type'

require_relative 'integer_value_enum_mapper'
require_relative 'string_value_enum_mapper'

module ReeEnum
  module DSL
    def self.included(base)
      base.extend(ClassMethods)
    end

    def self.extended(base)
      base.extend(ClassMethods)
    end

    module ClassMethods
      def enum(name, &proc)
        dsl = Ree::ObjectDsl.new(
          Ree.container.packages_facade, name, self, :object
        )

        dsl.instance_exec(&proc) if block_given?

        dsl.tags(["object", "enum"])

        klass = dsl.object.klass
        klass.send(:include, ReeEnum::Enumerable)
        klass.setup_enum(dsl.object.name)
        Ree.container.compile(dsl.package, name)
      end

      def type_for_mapper
        return @type_for_mapper if defined? @type_for_mapper

        value_type = get_values.value_type

        klass = if value_type == String
          StringValueEnumMapper
        elsif value_type == Integer
          IntegerValueEnumMapper
        else
          raise NotImplementedError, "value_type #{value_type} is not supported"
        end

        @type_for_mapper = klass.new(self)
      end

      def register_as_swagger_type
        swagger_type_registrator = ReeSwagger::RegisterType.new

        definition = swagger_definition

        [:casters, :serializers].each do |kind|
          swagger_type_registrator.call(
            kind,
            type_for_mapper.class,
            ->(*) {
              definition
            }
          )
        end
      end

      def register_as_mapper_type
        register_as_swagger_type

        mapper_factory = ReeMapper.get_mapper_factory(
          Object.const_get(self.name.split('::').first)
        )

        mapper_factory.register_type(
          self.get_enum_name, type_for_mapper
        )
      end

      def swagger_definition
        value_type = get_values.value_type

        type = if value_type == String
          "string"
        elsif value_type == Integer
          "integer"
        else
          raise NotImplementedError, "value_type #{value_type} is not supported"
        end

        {
          type: type,
          enum: get_values.each.map(&:value)
        }
      end
    end
  end
end