# frozen_string_literal: true
RSpec.describe :build_serializer_schema do
  link :build_serializer_schema, from: :ree_swagger
  link :build_mapper_factory, from: :ree_mapper
  link :build_mapper_strategy, from: :ree_mapper

  let(:mapper_factory) {
    strategies = [
      build_mapper_strategy(method: :serialize, output: :symbol_key_hash),
    ]

    build_mapper_factory(
      strategies: strategies
    ).register(
      :unregistered_type,
      ReeMapper::Mapper.build(
        strategies,
        Class.new(ReeMapper::AbstractType) do
          def serialize(val, role: nil)
            val
          end
        end.new
      )
    )
  }

  let(:mapper) {
    setting_mapper = mapper_factory.call(register_as: :setting).use(:serialize) do
      string :name
      string :value
    end

    mapper_factory.call.use(:serialize) do
      integer   :id,            doc:  'Identificator'
      string    :name
      bool      :is_admin
      float     :free_space
      array     :tags,          each: string
      date_time :created_at
      date      :birth_day
      time      :updated_at

      setting   :one_setting
      array     :many_settings, each: setting

      hash      :cart do
        integer :size
      end

      array     :friends do
        integer :id
        string  :name
      end

      integer :test_null, null: true

      unregistered_type :test_unregistered_type
    end
  }

  it {
    expect(build_serializer_schema(mapper)).to eq(
      {
        type: 'object',
        properties: {
          id: { type: 'integer', description: 'Identificator' },
          name: { type: 'string' },
          is_admin: { type: 'boolean' },
          free_space: { type: 'number', format: 'float' },
          tags: { type: 'array', items: { type: 'string' } },
          created_at: { type: 'string', format: 'date-time' },
          birth_day: { type: 'string', format: 'date' },
          updated_at: { type: 'string', format: 'date-time' },
          one_setting: {
            type: 'object',
            properties: { name: { type: 'string' }, value: { type: 'string' } }
          },
          many_settings: {
            type: 'array',
            items: {
              type: 'object',
              properties: { name: { type: 'string' }, value: { type: 'string' } }
            }
          },
          cart: {
            type: 'object',
            properties: {
              size: { type: 'integer' }
            }
          },
          friends: {
            type: 'array',
            items: {
              type: 'object',
              properties: {
                id: { type: 'integer' },
                name: { type: 'string' }
              }
            }
          },
          test_null: {
            type: 'integer',
            nullable: true
          },
          test_unregistered_type: {}
        }
      }
    )
  }
end
