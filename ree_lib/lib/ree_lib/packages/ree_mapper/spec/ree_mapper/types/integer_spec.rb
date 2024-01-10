# frozen_string_literal: true

RSpec.describe 'ReeMapper::Integer' do
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
      integer :number
    }
  }

  describe '#cast' do
    it {
      expect(mapper.cast({ number: 1 })).to eq({ number: 1 })
    }

    it {
      expect(mapper.cast({ number: '1' })).to eq({ number: 1 })
    }

    it {
      expect { mapper.cast({ number: 'b1' }) }.to raise_error(ReeMapper::CoercionError, '`number` is invalid integer, got `"b1"`')
    }

    it {
      expect { mapper.cast({ number: '1b' }) }.to raise_error(ReeMapper::CoercionError, '`number` is invalid integer, got `"1b"`')
    }

    it {
      expect { mapper.cast({ number: 1.1 }) }.to raise_error(ReeMapper::TypeError, '`number` should be an integer, got `1.1`')
    }
  end

  describe '#serialize' do
    it {
      expect(mapper.serialize({ number: 1 })).to eq({ number: 1 })
    }

    it {
      expect { mapper.serialize({ number: '1' }) }.to raise_error(ReeMapper::TypeError, '`number` should be an integer, got `"1"`')
    }

    it {
      expect { mapper.serialize({ number: 'b1' }) }.to raise_error(ReeMapper::TypeError, '`number` should be an integer, got `"b1"`')
    }

    it {
      expect { mapper.serialize({ number: '1b' }) }.to raise_error(ReeMapper::TypeError, '`number` should be an integer, got `"1b"`')
    }

    it {
      expect { mapper.serialize({ number: 1.1 }) }.to raise_error(ReeMapper::TypeError, '`number` should be an integer, got `1.1`')
    }
  end

  describe '#db_dump' do
    it {
      expect(mapper.db_dump({ number: 1 })).to eq({ number: 1 })
    }

    it {
      expect { mapper.db_dump({ number: '1' }) }.to raise_error(ReeMapper::TypeError, '`number` should be an integer, got `"1"`')
    }

    it {
      expect { mapper.db_dump({ number: 'b1' }) }.to raise_error(ReeMapper::TypeError, '`number` should be an integer, got `"b1"`')
    }

    it {
      expect { mapper.db_dump({ number: '1b' }) }.to raise_error(ReeMapper::TypeError, '`number` should be an integer, got `"1b"`')
    }

    it {
      expect { mapper.db_dump({ number: 1.1 }) }.to raise_error(ReeMapper::TypeError, '`number` should be an integer, got `1.1`')
    }
  end

  describe '#db_load' do
    it {
      expect(mapper.db_load({ number: 1 })).to eq({ number: 1 })
    }

    it {
      expect(mapper.db_load({ number: '1' })).to eq({ number: 1 })
    }

    it {
      expect { mapper.db_load({ number: 'b1' }) }.to raise_error(ReeMapper::CoercionError, '`number` is invalid integer, got `"b1"`')
    }

    it {
      expect { mapper.db_load({ number: '1b' }) }.to raise_error(ReeMapper::CoercionError, '`number` is invalid integer, got `"1b"`')
    }

    it {
      expect { mapper.db_load({ number: 1.1 }) }.to raise_error(ReeMapper::TypeError, '`number` should be an integer, got `1.1`')
    }
  end
end
