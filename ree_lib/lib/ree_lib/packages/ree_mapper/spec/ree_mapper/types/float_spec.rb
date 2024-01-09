# frozen_string_literal: true
require 'bigdecimal'

RSpec.describe 'ReeMapper::Float' do
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
      float :float
    }
  }

  describe '#cast' do
    it {
      expect(mapper.cast({ float: 1.1 })).to eq({ float: 1.1 })
    }

    it {
      expect(mapper.cast({ float: '1.1' })).to eq({ float: 1.1 })
    }

    it {
      expect(mapper.cast({ float: BigDecimal("1.1") })).to eq({ float: 1.1 })
    }

    it {
      expect(mapper.cast({ float: 1 })).to eq({ float: 1.0 })
    }

    it {
      expect { mapper.cast({ float: 'a1.1' }) }.to raise_error(ReeMapper::CoercionError, '`float` is invalid float, got `"a1.1"`')
    }

    it {
      expect { mapper.cast({ float: '1.1a' }) }.to raise_error(ReeMapper::CoercionError, '`float` is invalid float, got `"1.1a"`')
    }

    it {
      object = Object.new
      expect { mapper.cast({ float: object }) }.to raise_error(ReeMapper::TypeError, "`float` should be a float, got `#{object.inspect}`")
    }
  end

  describe '#serialize' do
    it {
      expect(mapper.serialize({ float: 1.1 })).to eq({ float: 1.1 })
    }

    it {
      expect { mapper.serialize({ float: '1.1' }) }.to raise_error(ReeMapper::TypeError, "`float` should be a float, got `\"1.1\"`")
    }

    it {
      expect { mapper.serialize({ float: nil }) }.to raise_error(ReeMapper::TypeError, "`float` should be a float, got `nil`")
    }

    it {
      object = Object.new
      expect { mapper.serialize({ float: object }) }.to raise_error(ReeMapper::TypeError, "`float` should be a float, got `#{object.inspect}`")
    }
  end

  describe '#db_dump' do
    it {
      expect(mapper.db_dump({ float: 1.1 })).to eq({ float: 1.1 })
    }

    it {
      expect { mapper.db_dump({ float: '1.1' }) }.to raise_error(ReeMapper::TypeError, "`float` should be a float, got `\"1.1\"`")
    }

    it {
      expect { mapper.db_dump({ float: nil }) }.to raise_error(ReeMapper::TypeError, "`float` should be a float, got `nil`")
    }

    it {
      object = Object.new
      expect { mapper.db_dump({ float: object }) }.to raise_error(ReeMapper::TypeError, "`float` should be a float, got `#{object.inspect}`")
    }
  end

  describe '#db_load' do
    it {
      expect(mapper.db_load({ float: 1.1 })).to eq({ float: 1.1 })
    }

    it {
      expect(mapper.db_load({ float: '1.1' })).to eq({ float: 1.1 })
    }

    it {
      expect(mapper.db_load({ float: BigDecimal("1.1") })).to eq({ float: 1.1 })
    }

    it {
      expect(mapper.db_load({ float: 1 })).to eq({ float: 1.0 })
    }

    it {
      expect { mapper.db_load({ float: 'a1.1' }) }.to raise_error(ReeMapper::CoercionError, '`float` is invalid float, got `"a1.1"`')
    }

    it {
      expect { mapper.db_load({ float: '1.1a' }) }.to raise_error(ReeMapper::CoercionError, '`float` is invalid float, got `"1.1a"`')
    }

    it {
      expect { mapper.db_load({ float: nil }) }.to raise_error(ReeMapper::TypeError, "`float` should be a float, got `nil`")
    }

    it {
      object = Object.new
      expect { mapper.db_load({ float: object }) }.to raise_error(ReeMapper::TypeError, "`float` should be a float, got `#{object.inspect}`")
    }
  end
end
