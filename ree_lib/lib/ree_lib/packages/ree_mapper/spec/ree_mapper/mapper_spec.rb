# frozen_string_literal: true
package_require "ree_mapper"

RSpec.describe ReeMapper::Mapper do
  link :build_mapper_factory, from: :ree_mapper
  link :build_mapper_strategy, from: :ree_mapper

  describe '#:strategy_method' do
    let(:mapper) {
      build_mapper_factory(
        strategies: [
          build_mapper_strategy(method: :cast, dto: Hash),
        ]
      ).call.use(:cast) do
        integer :my_field
      end
    }

    it {
      expect(mapper.cast({ "my_field" => 1 })).to eq({ my_field: 1 })
    }

    it {
      expect(mapper.cast({ my_field: 1 })).to eq({ my_field: 1 })
    }

    it {
      expect(mapper.cast(OpenStruct.new({ my_field: 1 }))).to eq({ my_field: 1 })
    }

    it {
      obj = Object.new
      obj.define_singleton_method(:my_field) { 1 }
      expect(mapper.cast(obj)).to eq({ my_field: 1 })
    }

    it "add mapper location to error full message" do
      mapper.cast({ my_field: "not number" })
    rescue => e
      expect(e.full_message).to include("located at")
    end
  end

  describe 'hash dto' do
    let(:mapper) {
      build_mapper_factory(
        strategies: [
          build_mapper_strategy(method: :cast, dto: Hash),
        ]
      ).call.use(:cast) do
        integer :my_field
      end
    }

    it {
      expect(mapper.cast({ my_field: 1 })).to eq({ my_field: 1 })
    }
  end

  describe 'ostruct dto' do
    let(:mapper) {
      build_mapper_factory(
        strategies: [
          build_mapper_strategy(method: :cast, dto: OpenStruct),
        ]
      ).call.use(:cast) do
        integer :my_field
      end
    }

    it {
      expect(mapper.cast({ my_field: 1 }).to_h).to eq({ my_field: 1 })
    }

    it {
      expect(mapper.cast({ my_field: 1 })).to be_a(OpenStruct)
    }
  end

  describe 'struct dto' do
    let(:mapper) {
      build_mapper_factory(
        strategies: [
          build_mapper_strategy(method: :cast, dto: Struct),
        ]
      ).call.use(:cast) do
        integer :my_field
        hash :hsh do
          integer :nested_field
        end
      end
    }

    it {
      nested_struct = Struct.new(:nested_field)
      struct = Struct.new(:my_field, :hsh)
      expect(mapper.cast({ my_field: 1, hsh: { nested_field: 1 } }).inspect).to eq(
        struct.new(1, nested_struct.new(1)).inspect
      )
    }

    it {
      expect(mapper.cast({ my_field: 1, hsh: { nested_field: 1 } })).to be_a(Struct)
    }
  end

  describe 'object dto' do
    let(:dto) { Class.new }
    let(:mapper) {
      build_mapper_factory(
        strategies: [
          build_mapper_strategy(method: :cast, dto: Object),
        ]
      ).call.use(:cast, dto: dto) do
        integer :my_field
      end
    }

    it {
      result = mapper.cast({ my_field: 1 })
      expect(result.instance_variable_get(:@my_field)).to eq(1)
    }

    it {
      result = mapper.cast({ my_field: 1 })
      expect(result).to be_a(dto)
    }
  end

  describe 'always_optional' do
    let(:mapper_factory) {
      build_mapper_factory(
        strategies: [
          build_mapper_strategy(method: :cast, dto: Hash, always_optional: true),
        ]
      )
    }
    let(:mapper) {
      mapper_factory.call.use(:cast) do
        integer :my_field
      end
    }

    it {
      expect(mapper.cast({})).to eq({})
    }
  end

  describe '#dto' do
    let(:mapper_factory) {
      build_mapper_factory(
        strategies: [
          build_mapper_strategy(method: :cast, dto: Hash, always_optional: true),
          build_mapper_strategy(method: :serialize, dto: Object),
        ]
      )
    }
    let(:mapper) {
      mapper_factory.call.use(:cast).use(:serialize, dto: Struct) do
        integer :my_field
      end
    }

    it {
      expect(mapper.dto(:cast)).to eq(Hash)
    }

    it {
      expect(mapper.dto(:serialize)).to be < Struct
    }

    it {
      expect { mapper.dto(:db_dump) }.to raise_error(ArgumentError, "there is no :db_dump strategy")
    }
  end

  describe '#find_strategy' do
    let(:mapper_factory) {
      build_mapper_factory(
        strategies: [
          build_mapper_strategy(method: :cast),
          build_mapper_strategy(method: :serialize),
        ]
      )
    }
    let(:mapper) {
      mapper_factory.call.use(:cast) do
        integer :my_field
      end
    }

    it {
      expect(mapper.find_strategy(:cast)).to be_a(ReeMapper::MapperStrategy)
    }

    it {
      expect(mapper.find_strategy(:serialize)).to be_nil
    }
  end
end
