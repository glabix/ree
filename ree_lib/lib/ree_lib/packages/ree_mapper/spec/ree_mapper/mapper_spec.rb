# frozen_string_literal: true

RSpec.describe ReeMapper::Mapper do
  link :build_mapper_factory, from: :ree_mapper
  link :build_mapper_strategy, from: :ree_mapper

  describe 'input' do
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
end
