# frozen_string_literal: true
RSpec.describe :build_serializer_schema do
  link :build_mapper_factory, from: :ree_mapper
  link :build_mapper_strategy, from: :ree_mapper
  link :build_serializer_schema, from: :ree_swagger

  let(:mapper_factory) {
    strategies = [
      build_mapper_strategy(method: :serialize, dto: Hash),
    ]

    build_mapper_factory(
      strategies: strategies
    ).register_type(
      :unregistered_type,
      Class.new(ReeMapper::AbstractType) do
        def serialize(val, role: nil)
          val
        end
      end.new
    )
  }

  let(:mapper) {
    nested_partial_mapper = mapper_factory.call(register_as: :nested_partial).use(:serialize) do
      string :included
      string :excepted
      string :nested_excepted
    end

    partial_mapper = mapper_factory.call(register_as: :partial).use(:serialize) do
      string :excepted
      nested_partial :nested_partial_value, except: [:excepted]
    end

    setting_mapper = mapper_factory.call(register_as: :setting).use(:serialize) do
      string :name
      string :value
    end

    mapper_factory.call.use(:serialize) do
      integer   :id,            doc:    'Identificator'
      string    :name
      bool      :is_admin
      float     :free_space
      array     :tags,          string
      date_time :created_at
      date      :birth_day
      time      :updated_at

      setting   :one_setting
      array     :many_settings, setting

      hash      :cart do
        integer :size
      end

      array     :friends do
        integer :id
        string  :name
      end

      integer :test_null, null: true

      unregistered_type :test_unregistered_type

      partial :partial_value, except: [:excepted, nested_partial_value: [:nested_excepted]]
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
          test_unregistered_type: {},
          partial_value: {
            type: 'object',
            properties: {
              nested_partial_value: {
                type: 'object',
                properties: {
                  included: { type: 'string' }
                }
              }
            }
          },
        }
      }
    )
  }
end
