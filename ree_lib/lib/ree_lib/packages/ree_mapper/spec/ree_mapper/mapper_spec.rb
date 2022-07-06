# frozen_string_literal: true

RSpec.describe ReeMapper::Mapper do
  link :build_mapper_factory, from: :ree_mapper
  link :build_mapper_strategy, from: :ree_mapper

  describe 'input' do
    let(:mapper) {
      build_mapper_factory(
        strategies: [
          build_mapper_strategy(method: :cast, output: :symbol_key_hash),
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

  describe 'string key hash output' do
    let(:mapper) {
      build_mapper_factory(
        strategies: [
          build_mapper_strategy(method: :cast, output: :string_key_hash),
        ]
      ).call.use(:cast) do
        integer :my_field
      end
    }

    it {
      expect(mapper.cast({ my_field: 1 })).to eq({ 'my_field' => 1 })
    }
  end

  describe 'string key hash output' do
    let(:mapper) {
      build_mapper_factory(
        strategies: [
          build_mapper_strategy(method: :cast, output: :symbol_key_hash),
        ]
      ).call.use(:cast) do
        integer :my_field
      end
    }

    it {
      expect(mapper.cast({ my_field: 1 })).to eq({ my_field: 1 })
    }
  end

  describe 'object output' do
    let(:dto) { Class.new }
    let(:mapper) {
      build_mapper_factory(
        strategies: [
          build_mapper_strategy(method: :cast, output: :object),
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
          build_mapper_strategy(method: :cast, output: :symbol_key_hash, always_optional: true),
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
