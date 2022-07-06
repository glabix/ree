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
    module ReeEnum
      class States
        include ReeEnum::DSL

        enum :states
    
        val :first, 0
        val :second, 1
      end

      class Types
        include ReeEnum::DSL

        enum :types

        val :account, 0
      end

      class TestObject
        contract(ReeEnum::States => nil)
        def call(value)
          # do nothing
        end
      end
    end

    obj = ReeEnum::States.new
    klass = ReeEnum::States

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
      ReeEnum::TestObject.new.call(obj.first)
    }.to_not raise_error

    expect {
      ReeEnum::TestObject.new.call('invalid')
    }.to raise_error do |e|
      expect(e).to be_a(Ree::Contracts::ContractError)
      expect(e.message).to eq("Contract violation for ReeEnum::TestObject#call\n\t - value: expected one of ReeEnum::States, got String => \"invalid\"")
    end
  }
end