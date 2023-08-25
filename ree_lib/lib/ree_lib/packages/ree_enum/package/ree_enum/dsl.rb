package_require 'ree_swagger/functions/register_type'

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
        @type_for_mapper ||= begin
          klass = Class.new(ReeMapper::AbstractType) do
            def initialize(enum)
              @enum = enum
            end

            contract(
              ReeEnum::Value,
              Kwargs[
                name: String,
                role: Nilor[Symbol, ArrayOf[Symbol]]
              ] => String
            )
            def serialize(value, name:, role: nil)
              value.to_s
            end

            contract(
              Any,
              Kwargs[
                name: String,
                role: Nilor[Symbol, ArrayOf[Symbol]]
              ] => ReeEnum::Value
            ).throws(ReeMapper::CoercionError)
            def cast(value, name:, role: nil)
              enum_value = if value.is_a?(String)
                @enum.get_values.by_value(value)
              elsif value.is_a?(ReeEnum::Value)
                @enum.get_values.each.find { _1 == value }
              end

              if enum_value.nil?
                raise ReeMapper::CoercionError, "`#{name}` should be one of #{enum_inspection}"
              end

              enum_value
            end

            contract(
              ReeEnum::Value,
              Kwargs[
                name: String,
                role: Nilor[Symbol, ArrayOf[Symbol]]
              ] => Or[Integer, String]
            )
            def db_dump(value, name:, role: nil)
              value.mapped_value
            end

            contract(
              Or[Integer, String],
              Kwargs[
                name: String,
                role: Nilor[Symbol, ArrayOf[Symbol]]
              ] => ReeEnum::Value
            ).throws(ReeMapper::CoercionError)
            def db_load(value, name:, role: nil)
              enum_val = @enum.get_values.by_mapped_value(value)

              if !enum_val
                raise ReeMapper::CoercionError, "`#{name}` should be one of #{enum_inspection}"
              end

              enum_val
            end

            private

            def enum_inspection
              @enum_inspect ||= truncate(@enum.get_values.each.map(&:to_s).inspect)
            end

            def truncate(str, limit = 180)
              return str if str.length <= limit
              "#{str[0..limit]}..."
            end
          end

          klass.new(self)
        end
      end

      def register_as_swagger_type
        swagger_type_registrator = ReeSwagger::RegisterType.new

        [:casters, :serializers].each do |kind|
          swagger_type_registrator.call(
            kind,
            type_for_mapper.class,
            ->(*) {
              {
                type: 'string',
                enum: get_values.each.map(&:to_s)
              }
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
    end
  end
end