# frozen_string_literal: true
package_require('ree_enum/dsl')

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

        val :account, 0

        register_as_mapper_type
      end

      class TestMapper
        include ReeMapper::DSL

        mapper :test_mapper do
          link :states
          link :types
        end

        class Dto
          attr_reader :type, :state
          def initialize(type, state)
            @type = type
            @state = state
          end
        end

        build_mapper.use(:serialize).use(:cast).use(:db_dump).use(:db_load, dto: Dto) do
          types :type
          states :state
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
      expect(o.by_value(:first)).to eq(o.first)
      expect(o.by_value(:second)).to eq(o.second)
      expect(o.by_number(0)).to eq(o.first)
      expect(o.by_number(1)).to eq(o.second)
      expect(o.all).to eq([o.first, o.second])
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
      })
    ).to eq(
      {
        state: 'first',
        type: 'account'
      }
    )

    expect {
      mapper.cast({
        state: 'first',
        type: 'invalid',
      })
      }.to raise_error(ReeMapper::CoercionError, '`type` should be one of ["account"]')

    expect(
      mapper.cast({
        state: 'first',
        type: 'account',
      })
    ).to eq(
      {
        state: TestReeEnum::States.first,
        type: TestReeEnum::Types.account
      }
    )

    expect(
      mapper.cast({
        state: TestReeEnum::States.first,
        type: TestReeEnum::Types.account,
      })
    ).to eq(
      {
        state: TestReeEnum::States.first,
        type: TestReeEnum::Types.account
      }
    )

    expect(
      mapper.db_dump({
        state: TestReeEnum::States.first,
        type: TestReeEnum::Types.account,
      })
    ).to eq(
      {
        state: 0,
        type: 0
      }
    )

    dto = mapper.db_load({
      state: 0,
      type: 0,
    })

    expect(dto.state).to eq(TestReeEnum::States.first)
    expect(dto.state).to be_a(ReeEnum::Value)
    expect(dto.type).to eq(TestReeEnum::Types.account)
    expect(dto.type).to be_a(ReeEnum::Value)
  }
end