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
              if value.is_a?(String)
                enum_val = @enum.values.all.detect { |v| v.to_s == value }

                if !enum_val
                  raise ReeMapper::CoercionError, "`#{name}` should be one of #{@enum.values.all.map(&:to_s).inspect}"
                end

                enum_val
              elsif value.is_a?(Integer)
                enum_val = @enum.values.all.detect { |v| v.to_i == value }

                if !enum_val
                  raise ReeMapper::CoercionError, "`#{name}` should be one of #{@enum.values.all.map(&:to_s).inspect}"
                end

                enum_val
              else
                raise ReeMapper::CoercionError, "`#{name}` should be one of #{@enum.values.all.map(&:to_s).inspect}"
              end
            end

            contract(
              ReeEnum::Value,
              Kwargs[
                name: String,
                role: Nilor[Symbol, ArrayOf[Symbol]]
              ] => Integer
            )
            def db_dump(value, name:, role: nil)
              value.to_i
            end

            contract(
              Integer,
              Kwargs[
                name: String,
                role: Nilor[Symbol, ArrayOf[Symbol]]
              ] => ReeEnum::Value
            ).throws(ReeMapper::TypeError)
            def db_load(value, name:, role: nil)
              cast(value, name: name, role: role)
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
                enum: values.all.map(&:to_s)
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
          self.enum_name, type_for_mapper
        )
      end
    end
  end
end