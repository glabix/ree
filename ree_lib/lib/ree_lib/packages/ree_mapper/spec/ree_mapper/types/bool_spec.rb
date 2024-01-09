# frozen_string_literal: true

RSpec.describe 'ReeMapper::Bool' do
  link :build_mapper_factory, from: :ree_mapper
  link :build_mapper_strategy, from: :ree_mapper

  let(:mapper_factory) {
    build_mapper_factory(
      strategies: [
        build_mapper_strategy(method: :cast,      dto: Hash),
        build_mapper_strategy(method: :serialize, dto: Hash),
        build_mapper_strategy(method: :db_dump,   dto: Hash),
        build_mapper_strategy(method: :db_load,   dto: Hash)
      ]
    )
  }

  let(:mapper) {
    mapper_factory.call.use(:cast).use(:serialize).use(:db_dump).use(:db_load) {
      bool :bool
    }
  }

  describe '#serialize' do
    it {
      expect(mapper.serialize({ bool: true })).to eq({ bool: true })
    }

    it {
      expect(mapper.serialize({ bool: false })).to eq({ bool: false })
    }

    it {
      expect { mapper.serialize({ bool: 'true' }) }.to raise_error(ReeMapper::TypeError, "`bool` should be a boolean, got `\"true\"`")
    }

    it {
      expect { mapper.serialize({ bool: 1 }) }.to raise_error(ReeMapper::TypeError, "`bool` should be a boolean, got `1`")
    }
  end

  describe '#cast' do
    it {
      expect(mapper.cast({ 'bool' => true })).to eq({ bool: true })
    }

    it {
      expect(mapper.cast({ 'bool' => '1' })).to eq({ bool: true })
    }

    it {
      expect(mapper.cast({ 'bool' => 'true' })).to eq({ bool: true })
    }

    it {
      expect(mapper.cast({ 'bool' => 'on' })).to eq({ bool: true })
    }

    it {
      expect(mapper.cast({ 'bool' => 1 })).to eq({ bool: true })
    }

    it {
      expect(mapper.cast({ 'bool' => false })).to eq({ bool: false })
    }

    it {
      expect(mapper.cast({ 'bool' => '0' })).to eq({ bool: false })
    }

    it {
      expect(mapper.cast({ 'bool' => 'false' })).to eq({ bool: false })
    }

    it {
      expect(mapper.cast({ 'bool' => 'off' })).to eq({ bool: false })
    }

    it {
      expect(mapper.cast({ 'bool' => 0 })).to eq({ bool: false })
    }

    it {
      expect { mapper.cast({ 'bool' => 'right' }) }.to raise_error(ReeMapper::CoercionError, "`bool` is invalid boolean, got `\"right\"`")
    }

    it {
      object = Object.new
      expect { mapper.cast({ 'bool' => object }) }.to raise_error(ReeMapper::CoercionError, "`bool` is invalid boolean, got `#{object.inspect}`")
    }
  end

  describe '#db_dump' do
    it {
      expect(mapper.db_dump(OpenStruct.new({ bool: true }))).to eq({ bool: true })
    }

    it {
      expect(mapper.db_dump(OpenStruct.new({ bool: false }))).to eq({ bool: false })
    }

    it {
      expect { mapper.db_dump(OpenStruct.new({ bool: 'true' })) }.to raise_error(ReeMapper::TypeError, "`bool` should be a boolean, got `\"true\"`")
    }

    it {
      expect { mapper.db_dump(OpenStruct.new({ bool: 1 })) }.to raise_error(ReeMapper::TypeError, "`bool` should be a boolean, got `1`")
    }
  end

  describe '#db_load' do
    it {
      expect(mapper.db_load({ 'bool' => true })).to eq({ bool: true })
    }

    it {
      expect(mapper.db_load({ 'bool' => '1' })).to eq({ bool: true })
    }

    it {
      expect(mapper.db_load({ 'bool' => 'true' })).to eq({ bool: true })
    }

    it {
      expect(mapper.db_load({ 'bool' => 'on' })).to eq({ bool: true })
    }

    it {
      expect(mapper.db_load({ 'bool' => 1 })).to eq({ bool: true })
    }

    it {
      expect(mapper.db_load({ 'bool' => false })).to eq({ bool: false })
    }

    it {
      expect(mapper.db_load({ 'bool' => '0' })).to eq({ bool: false })
    }

    it {
      expect(mapper.db_load({ 'bool' => 'false' })).to eq({ bool: false })
    }

    it {
      expect(mapper.db_load({ 'bool' => 'off' })).to eq({ bool: false })
    }

    it {
      expect(mapper.db_load({ 'bool' => 0 })).to eq({ bool: false })
    }

    it {
      expect { mapper.db_load({ 'bool' => 'right' }) }.to raise_error(ReeMapper::CoercionError, "`bool` is invalid boolean, got `\"right\"`")
    }

    it {
      object = Object.new
      expect { mapper.db_load({ 'bool' => object }) }.to raise_error(ReeMapper::CoercionError, "`bool` is invalid boolean, got `#{object.inspect}`")
    }
  end
end
