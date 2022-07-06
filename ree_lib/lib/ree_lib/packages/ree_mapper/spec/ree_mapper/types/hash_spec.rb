# frozen_string_literal: true

RSpec.describe 'Mapper Hash' do
  link :build_mapper_factory, from: :ree_mapper
  link :build_mapper_strategy, from: :ree_mapper

  let(:mapper_factory) {
    build_mapper_factory(
      strategies: [
        build_mapper_strategy(method: :cast, output: :symbol_key_hash)
      ]
    )
  }

  let(:mapper) {
    mapper_factory.call.use(:cast) {
      hash :point do
        integer :x
        integer :y
      end
    }
  }

  describe '#cast' do
    it {
      expect(mapper.cast({ point: { x: 1, y: 1 } })).to eq({ point: { x: 1, y: 1 } })
    }

    it {
      expect { mapper.cast({ point: 1 }) }.to raise_error(ReeMapper::TypeError, 'Missing required field `x`')
    }
  end

  describe 'key: option' do
    it {
      expect(
        mapper_factory.call.use(:cast) {
          hash :point, key: :string do
            integer :x
            integer :y
          end
        }.cast({ point: { x: 1, y: 1 } })
      ).to eq({ point: { 'x' => 1, 'y' => 1 } })
    }

    it {
      expect(
        mapper_factory.call.use(:cast) {
          hash :point, key: :symbol do
            integer :x
            integer :y
          end
        }.cast({ point: { x: 1, y: 1 } })
      ).to eq({ point: { x: 1, y: 1 } })
    }

    it {
      expect {
        mapper_factory.call.use(:cast) {
          hash :point, key: :whatever do
            integer :x
            integer :y
          end
        }
      }.to raise_error(ArgumentError)
    }
  end

  describe 'parent strategy object output' do
    let(:mapper_factory) {
      build_mapper_factory(
        strategies: [
          build_mapper_strategy(method: :cast, output: :object)
        ]
      )
    }

    let(:mapper) {
      mapper_factory.call.use(:cast, dto: dto) {
        hash :point do
          integer :x
          integer :y
        end
      }
    }

    let(:dto) {
      Class.new do
        def ==(other)
          instance_variables == other.instance_variables
        end
      end
    }

    it {
      expect(mapper.cast({ point: { x: 1, y: 1 } })).to eq(Object.new.tap { _1.instance_exec { @point = { x: 1, y: 1 } } })
    }
  end
end
