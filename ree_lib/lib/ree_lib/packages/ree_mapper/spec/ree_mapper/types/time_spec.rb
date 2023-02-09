# frozen_string_literal: true

RSpec.describe 'ReeMapper::Time' do
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
      time :time
    }
  }

  describe '#serialize' do
    it {
      expect(mapper.serialize({ time: Time.new(2020) })).to eq({ time: Time.new(2020) })
    }

    it {
      expect { mapper.serialize({ time: DateTime.new(2020) }) }.to raise_error(ReeMapper::TypeError, "`time` should be a time")
    }

    it {
      expect { mapper.serialize({ time: Date.new(2020) }) }.to raise_error(ReeMapper::TypeError, "`time` should be a time")
    }

    it {
      expect { mapper.serialize({ time: DateTime.new(2020).to_s }) }.to raise_error(ReeMapper::TypeError, "`time` should be a time")
    }

    it {
      expect { mapper.serialize({ time: '2020-01-01' }) }.to raise_error(ReeMapper::TypeError, "`time` should be a time")
    }

    it {
      expect { mapper.serialize({ time: Object.new }) }.to raise_error(ReeMapper::TypeError, "`time` should be a time")
    }
  end

  describe '#cast' do
    it {
      expect(mapper.cast({ time: Time.new(2020) })).to eq({ time: Time.new(2020) })
    }

    it {
      expect(mapper.cast({ time: DateTime.new(2020) })).to eq({ time: DateTime.new(2020).to_time })
    }

    it {
      expect(mapper.cast({ time: Time.new(2020).to_s })).to eq({ time: Time.new(2020) })
    }

    it {
      expect(mapper.cast({ time: '2020-01-01' })).to eq({ time: Time.new(2020) })
    }

    it {
      expect { mapper.cast({ time: Date.new(2020) }) }.to raise_error(ReeMapper::TypeError, "`time` should be a time")
    }

    it {
      expect { mapper.cast({ time: Object.new }) }.to raise_error(ReeMapper::TypeError, "`time` should be a time")
    }

    it {
      expect { mapper.cast({ time: 'no date time' }) }.to raise_error(ReeMapper::CoercionError, "`time` is invalid time")
    }
  end

  describe '#db_dump' do
    it {
      expect(mapper.db_dump({ time: Time.new(2020) })).to eq({ time: Time.new(2020) })
    }

    it {
      expect { mapper.serialize({ time: DateTime.new(2020) }) }.to raise_error(ReeMapper::TypeError, "`time` should be a time")
    }

    it {
      expect { mapper.db_dump({ time: Date.new(2020) }) }.to raise_error(ReeMapper::TypeError, "`time` should be a time")
    }

    it {
      expect { mapper.db_dump({ time: Time.new(2020).to_s }) }.to raise_error(ReeMapper::TypeError, "`time` should be a time")
    }

    it {
      expect { mapper.db_dump({ time: '2020-01-01' }) }.to raise_error(ReeMapper::TypeError, "`time` should be a time")
    }

    it {
      expect { mapper.db_dump({ time: Object.new }) }.to raise_error(ReeMapper::TypeError, "`time` should be a time")
    }
  end

  describe '#db_load' do
    it {
      expect(mapper.db_load({ time: Time.new(2020) })).to eq({ time: Time.new(2020) })
    }

    it {
      expect(mapper.db_load({ time: DateTime.new(2020) })).to eq({ time: DateTime.new(2020).to_time })
    }

    it {
      expect(mapper.db_load({ time: Time.new(2020).to_s })).to eq({ time: Time.new(2020) })
    }

    it {
      expect(mapper.db_load({ time: '2020-01-01' })).to eq({ time: Time.new(2020) })
    }

    it {
      expect { mapper.db_load({ time: Date.new(2020) }) }.to raise_error(ReeMapper::TypeError, "`time` should be a time")
    }

    it {
      expect { mapper.db_load({ time: Object.new }) }.to raise_error(ReeMapper::TypeError, "`time` should be a time")
    }

    it {
      expect { mapper.db_load({ time: 'no date time' }) }.to raise_error(ReeMapper::CoercionError, "`time` is invalid time")
    }
  end
end
