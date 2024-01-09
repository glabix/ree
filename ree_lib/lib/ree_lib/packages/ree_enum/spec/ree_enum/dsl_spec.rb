# frozen_string_literal: true
package_require('ree_enum/dsl')
package_require('ree_swagger/functions/get_serializer_definition')

RSpec.describe ReeEnum::DSL do
  before do
    Ree.enable_irb_mode
  end

  after do
    Ree.disable_irb_mode
  end

  it {
    module TestReeEnum
      include Ree::PackageDSL

      package

      class States
        include ReeEnum::DSL

        enum :states

        val :first, 0
        val :second, 1

        register_as_mapper_type
      end

      class Types
        include ReeEnum::DSL

        enum :types

        val :account

        register_as_mapper_type
      end

      class Numbers
        include ReeEnum::DSL

        enum :numbers

        val 0, method: :zero
        val 1, method: :one

        register_as_mapper_type
      end

      class Reflexives
        include ReeEnum::DSL

        enum :reflexives

        val :self, method: :myself
        val :yourself
      end

      class ContentTypes
        include ReeEnum::DSL

        enum :content_types

        val "video/mp4"
        val "image/png"

        register_as_mapper_type
      end

      class TestMapper
        include ReeMapper::DSL

        mapper :test_mapper do
          link :numbers
          link :states
          link :types
        end

        class Dto
          attr_reader :type, :state, :number
          def initialize(type, state, number)
            @type = type
            @state = state
            @number = number
          end
        end

        build_mapper.use(:serialize).use(:cast).use(:db_dump).use(:db_load, dto: Dto) do
          types :type
          states :state
          numbers :number
        end
      end

      class TestObject
        contract(TestReeEnum::States => nil)
        def call(value)
          # do nothing
        end
      end
    end

    obj = TestReeEnum::States.new
    klass = TestReeEnum::States

    [obj, klass].each do |o|
      expect(o.first).to eq(:first)
      expect(o.first).to eq(0)
      expect(o.second).to eq(:second)
      expect(o.second).to eq(1)
      expect(o.get_values.by_value(:first)).to eq(o.first)
      expect(o.get_values.by_value(:second)).to eq(o.second)
      expect(o.get_values.by_value("first")).to eq(o.first)
      expect(o.get_values.by_value("second")).to eq(o.second)
      expect(o.get_values.by_mapped_value(0)).to eq(o.first)
      expect(o.get_values.by_mapped_value(1)).to eq(o.second)
      expect(o.get_values.to_a).to eq([o.first, o.second])
    end

    expect {
      TestReeEnum::TestObject.new.call(obj.first)
    }.to_not raise_error

    expect {
      TestReeEnum::TestObject.new.call('invalid')
    }.to raise_error do |e|
      expect(e).to be_a(Ree::Contracts::ContractError)
      expect(e.message).to eq("Contract violation for TestReeEnum::TestObject#call\n\t - value: expected one of TestReeEnum::States, got String => \"invalid\"")
    end

    mapper = TestReeEnum::TestMapper.new

    expect(
      mapper.serialize({
        state: TestReeEnum::States.first,
        type: TestReeEnum::Types.account,
        number: TestReeEnum::Numbers.zero,
      })
    ).to eq(
      {
        state: 'first',
        type: 'account',
        number: 0,
      }
    )

    expect {
      mapper.cast({
        state: 'first',
        type: 'invalid',
        number: 0,
      })
    }.to raise_error(ReeMapper::CoercionError, '`type` should be one of ["account"], got `"invalid"`')

    expect {
      mapper.db_load({
        state: 'first',
        type: 'invalid',
        number: 0,
      })
    }.to raise_error(ReeMapper::CoercionError, '`type` should be one of ["account"], got `"invalid"`')

    expect(
      mapper.cast({
        state: 'first',
        type: 'account',
        number: 0,
      })
    ).to eq(
      {
        state: TestReeEnum::States.first,
        type: TestReeEnum::Types.account,
        number: TestReeEnum::Numbers.zero,
      }
    )

    expect(
      mapper.cast({
        state: TestReeEnum::States.first,
        type: TestReeEnum::Types.account,
        number: TestReeEnum::Numbers.zero,
      })
    ).to eq(
      {
        state: TestReeEnum::States.first,
        type: TestReeEnum::Types.account,
        number: TestReeEnum::Numbers.zero,
      }
    )

    expect(
      mapper.cast({
        state: TestReeEnum::States.first,
        type: TestReeEnum::Types.account,
        number: TestReeEnum::Numbers.zero,
      })
    ).to eq(
      {
        state: "first",
        type: "account",
        number: 0,
      }
    )

    expect(
      mapper.db_dump({
        state: TestReeEnum::States.first,
        type: TestReeEnum::Types.account,
        number: TestReeEnum::Numbers.zero,
      })
    ).to eq(
      {
        state: 0,
        type: "account",
        number: 0,
      }
    )

    dto = mapper.db_load({
      state: 0,
      type: "account",
      number: 0,
    })

    expect(dto.state).to eq(TestReeEnum::States.first)
    expect(dto.state).to be_a(ReeEnum::Value)
    expect(dto.type).to eq(TestReeEnum::Types.account)
    expect(dto.type).to be_a(ReeEnum::Value)
    expect(dto.number).to eq(TestReeEnum::Numbers.zero)
    expect(dto.number).to be_a(ReeEnum::Value)

    expect(TestReeEnum::Reflexives.myself).to eq(:self)

    expect(TestReeEnum::ContentTypes.method_defined?(:"video/mp4")).to be_falsey

    swagger_definition_fetcher = ReeSwagger::GetSerializerDefinition.new
    expect(
      swagger_definition_fetcher.call(TestReeEnum::Reflexives.type_for_mapper, -> {})
    ).not_to eq(
      swagger_definition_fetcher.call(TestReeEnum::ContentTypes.type_for_mapper, -> {})
    )
  }
end