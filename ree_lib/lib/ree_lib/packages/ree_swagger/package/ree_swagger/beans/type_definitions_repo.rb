class ReeSwagger::TypeDefinitionsRepo
  include Ree::BeanDSL

  bean :type_definitions_repo do
    singleton
    factory :build
  end

  def build
    {
      serializers: {
        ReeMapper::Integer => ->(*) {
          { type: 'integer' }
        },
        ReeMapper::String => ->(*) {
          { type: 'string' }
        },
        ReeMapper::Bool => ->(*) {
          { type: 'boolean' }
        },
        ReeMapper::Float => ->(*) {
          {
            type: 'number',
            format: 'float'
          }
        },
        ReeMapper::Array => ->(type, build_serializer_schema) {
          {
            type: 'array',
            items: build_serializer_schema.(type.of.type)
          }
        },
        ReeMapper::DateTime => ->(*) {
          {
            type: 'string',
            format: 'date-time'
          }
        },
        ReeMapper::Date => ->(*) {
          {
            type: 'string',
            format: 'date'
          }
        },
        ReeMapper::Time => ->(*) {
          {
            type: 'string',
            format: 'date-time'
          }
        }
      },
      casters: {
        ReeMapper::Integer => ->(*) {
          { type: 'integer' }
        },
        ReeMapper::String => ->(*) {
          { type: 'string' }
        },
        ReeMapper::Bool => ->(*) {
          { type: 'boolean' }
        },
        ReeMapper::Float => ->(*) {
          {
            type: 'number',
            format: 'float'
          }
        },
        ReeMapper::Array => ->(type, build_caster_schema) {
          {
            type: 'array',
            items: build_caster_schema.(type.of.type)
          }
        },
        ReeMapper::DateTime => ->(*) {
          {
            type: 'string',
            format: 'date-time'
          }
        },
        ReeMapper::Date => ->(*) {
          {
            type: 'string',
            format: 'date'
          }
        },
        ReeMapper::Time => ->(*) {
          {
            type: 'string',
            format: 'date-time'
          }
        }
      }
    }
  end
end
