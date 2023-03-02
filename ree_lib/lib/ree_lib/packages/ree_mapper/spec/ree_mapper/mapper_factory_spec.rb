# frozen_string_literal: true
package_require('ree_mapper/mapper_factory')

RSpec.describe ReeMapper::MapperFactory do
  link :build_mapper_factory, from: :ree_mapper
  link :build_mapper_strategy, from: :ree_mapper

  let(:strategies) { [build_mapper_strategy(method: :cast, dto: Hash)] }
  let(:mapper_factory) { build_mapper_factory(strategies: strategies) }

  let(:mapper_type) {
    Class.new(ReeMapper::AbstractType) do
      def cast(*); end
    end
  }

  describe '.register_type' do
    it {
      mapper_factory.register_type(:new_type, mapper_type.new)
      expect(mapper_factory.instance_methods).to include(:new_type)
    }

    it {
      mapper_factory.register_type(:new_type, mapper_type.new, strategies: [])

      expect {
        mapper_factory.call.use(:cast) do
          new_type :settings
        end
      }.to raise_error(ReeMapper::UnsupportedTypeError)
    }
  end

  describe '.register' do
    it {
      mapper_factory.register(:new_type, ReeMapper::Mapper.build(strategies, mapper_type.new))
      expect(mapper_factory.instance_methods).to include(:new_type)
    }

    it 'raise an error if the type is already registered' do
      mapper_factory.register(:new_type, ReeMapper::Mapper.build(strategies, mapper_type.new))

      expect {
        mapper_factory.register(:new_type, ReeMapper::Mapper.build(strategies, mapper_type.new))
      }.to raise_error(ArgumentError, 'type :new_type already registered')
    end

    it 'raise an error if the type is ended by ?' do
      expect {
        mapper_factory.register(:new_type?, ReeMapper::Mapper.build(strategies, mapper_type.new))
      }.to raise_error(ArgumentError)
    end

    it 'raise an error if the type method is already registered' do
      expect {
        mapper_factory.register(:array, ReeMapper::Mapper.build(strategies, mapper_type.new))
      }.to raise_error(ArgumentError, 'method :array already defined')
    end
  end

  describe '.use' do
    it {
      mapper = mapper_factory.call.use(:cast) do
        integer :id
      end

      expect(mapper).to be_a(ReeMapper::Mapper)
    }

    it {
      mapper_factory.register(:new_type, ReeMapper::Mapper.build([], mapper_type.new))

      expect {
        mapper_factory.call.use(:cast) do
          new_type :settings
        end
      }.to raise_error(ReeMapper::UnsupportedTypeError)
    }

    it {
      mapper_factory.call(register_as: :user).use(:cast) do
        integer :id
      end

      expect(mapper_factory.instance_methods).to include(:user)
    }

    it {
      expect {
        mapper_factory.call.use(:not_found) do
          integer :id
        end
      }.to raise_error(ArgumentError, 'MapperFactory strategy :not_found not found')
    }

    it {
      expect {
        mapper_factory.call.use(:cast) do
        end
      }.to raise_error(ReeMapper::ArgumentError, "mapper should contain at least one field")
    }
  end
end
