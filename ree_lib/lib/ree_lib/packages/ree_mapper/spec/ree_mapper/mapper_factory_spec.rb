# frozen_string_literal: true
package_require('ree_mapper/mapper_factory')

RSpec.describe ReeMapper::MapperFactory do
  link :build_mapper_factory, from: :ree_mapper
  link :build_mapper_strategy, from: :ree_mapper

  let(:cast_strategy) { build_mapper_strategy(method: :cast, dto: Hash) }
  let(:serialize_strategy) { build_mapper_strategy(method: :serialize, dto: Hash) }
  let(:mapper_factory) { build_mapper_factory(strategies: [cast_strategy, serialize_strategy]) }

  describe '.register_type' do
    let(:mapper_type) {
      Class.new(ReeMapper::AbstractType) do
        def cast(*); :value end
        def serialize(*); end
      end
    }

    it {
      mapper_factory.register_type(:new_type, mapper_type.new)
      expect(
        mapper_factory.call.use(:cast) { new_type :val }.cast({ val: :any })
      ).to eq({ val: :value })
    }

    it {
      mapper_factory.register_type(:new_type, mapper_type.new, strategies: [cast_strategy])
      expect(
        mapper_factory.call.use(:cast) { new_type :val }.cast({ val: :any })
      ).to eq({ val: :value })
    }
  end

  describe '.register_mapper' do
    let(:serializer) { mapper_factory.call.use(:serialize) { integer :id } }

    it {
      mapper_factory.register_mapper(:new_type, serializer)

      expect(
        mapper_factory.call.use(:serialize) { new_type :val }.serialize({ val: { id: 1 } })
      ).to eq({ val: { id: 1 } })
    }

    it 'allow to register caster and serializer with the same name' do
      caster = mapper_factory.call.use(:cast) { string :name }

      mapper_factory.register_mapper(:new_type, serializer)
      mapper_factory.register_mapper(:new_type, caster)

      expect(
        mapper_factory.call.use(:serialize) { new_type :val }.serialize({ val: { id: 1 } })
      ).to eq({ val: { id: 1 } })

      expect(
        mapper_factory.call.use(:cast) { new_type :val }.cast({ val: { name: '1' } })
      ).to eq({ val: { name: '1' } })
    end

    it 'raise an error if the mapper is already registered' do
      mapper_factory.register_mapper(:new_type, serializer)

      expect {
        mapper_factory.register_mapper(:new_type, serializer)
      }.to raise_error(ArgumentError, 'type :new_type with `serialize` strategy already registered')
    end

    it 'raise an error if the mapper name is ended by ?' do
      expect {
        mapper_factory.register_mapper(:new_type?, serializer)
      }.to raise_error(ArgumentError, 'mapper registration name should not end with `?`')
    end

    it 'raise an error if the mapper name is reserved' do
      expect {
        mapper_factory.register_mapper(:array, serializer)
      }.to raise_error(ArgumentError, 'method :array already defined')
    end
  end

  describe '.register_wrapper' do
    let(:round_wrapper) {
      Class.new(ReeMapper::AbstractWrapper) do
        def serialize(value, name:, **opts)
          raise ReeMapper::TypeError, "`#{name}` should be a number" if !value.is_a?(Numeric)

          subject.type.serialize(value.round, name: name, **opts)
        end
      end
    }

    it {
      mapper_factory.register_wrapper(:round, round_wrapper)

      expect(
        mapper_factory.call.use(:serialize) { round :val, integer }.serialize({ val: 1.1 })
      ).to eq({ val: 1 })
    }

    it 'allow to register caster and serializer with the same name' do
      caster_round_wrapper = Class.new(ReeMapper::AbstractWrapper) do
        def cast(value, name:, **opts)
          value = subject.type.cast(value, name: name, **opts)

          raise ReeMapper::TypeError, "`#{name}` should be a number" if !value.is_a?(Numeric)
          value.round
        end
      end

      mapper_factory.register_wrapper(:round, round_wrapper)
      mapper_factory.register_wrapper(:round, caster_round_wrapper)

      expect(
        mapper_factory.call.use(:serialize) { round :val, integer }.serialize({ val: 1.1 })
      ).to eq({ val: 1 })

      expect(
        mapper_factory.call.use(:cast) { round :val, float }.cast({ val: '1.1' })
      ).to eq({ val: 1 })
    end

    it 'raise an error if the registration wrapper name is ended by ?' do
      expect {
        mapper_factory.register_wrapper(:new_type?, round_wrapper)
      }.to raise_error(ArgumentError, 'wrapper registration name should not end with `?`')
    end

    it 'raise an error if name is reserved' do
      expect {
        mapper_factory.register_wrapper(:hash, round_wrapper)
      }.to raise_error(ArgumentError, 'method :hash already defined')
    end

    it 'raise an error if name is reserved by mapper' do
      expect {
        mapper_factory.register_wrapper(:integer, round_wrapper)
      }.to raise_error(ArgumentError, 'method :integer already defined')
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
      serializer = mapper_factory.call.use(:serialize) do
        integer :my_field
      end

      mapper_factory.register_mapper(:new_type, serializer)

      expect {
        mapper_factory.call.use(:cast) do
          new_type :settings
        end
      }.to raise_error(ReeMapper::UnsupportedTypeError, 'type :new_type should implement `cast`')
    }

    it {
      mapper_factory.call(register_as: :user).use(:cast) do
        integer :id
      end

      expect(
        mapper_factory.call.use(:cast) { user :user }.cast({ user: { id: 1 } })
      ).to eq({ user: { id: 1 } })
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

  describe '.find_strategy' do
    it {
      expect(mapper_factory.find_strategy(:cast)).to eq(cast_strategy)
    }

    it {
      expect(mapper_factory.find_strategy(:unknown)).to be_nil
    }
  end
end
