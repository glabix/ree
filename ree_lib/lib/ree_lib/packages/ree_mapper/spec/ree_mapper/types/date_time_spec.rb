# frozen_string_literal: true

RSpec.describe 'ReeMapper::DateTime' do
  link :build_mapper_factory, from: :ree_mapper
  link :build_mapper_strategy, from: :ree_mapper

  let(:mapper_factory) {
    build_mapper_factory(
      strategies: [
        build_mapper_strategy(method: :cast,      output: :symbol_key_hash),
        build_mapper_strategy(method: :serialize, output: :symbol_key_hash),
        build_mapper_strategy(method: :db_dump,   output: :symbol_key_hash),
        build_mapper_strategy(method: :db_load,   output: :symbol_key_hash)
      ]
    )
  }

  let(:mapper) {
    mapper_factory.call.use(:cast).use(:serialize).use(:db_dump).use(:db_load) {
      date_time :date_time
    }
  }

  describe '#serialize' do
    it {
      expect(mapper.serialize({ date_time: DateTime.new(2020) })).to eq({ date_time: DateTime.new(2020) })
    }

    it {
      expect { mapper.serialize({ date_time: Time.new(2020) }) }.to raise_error(ReeMapper::TypeError, "`date_time` should be a datetime")
    }

    it {
      expect { mapper.serialize({ date_time: Date.new(2020) }) }.to raise_error(ReeMapper::TypeError, "`date_time` should be a datetime")
    }

    it {
      expect { mapper.serialize({ date_time: DateTime.new(2020).to_s }) }.to raise_error(ReeMapper::TypeError, "`date_time` should be a datetime")
    }

    it {
      expect { mapper.serialize({ date_time: '2020-01-01' }) }.to raise_error(ReeMapper::TypeError, "`date_time` should be a datetime")
    }

    it {
      expect { mapper.serialize({ date_time: Object.new }) }.to raise_error(ReeMapper::TypeError, "`date_time` should be a datetime")
    }
  end

  describe '#cast' do
    it {
      expect(mapper.cast({ 'date_time' => DateTime.new(2020) })).to eq({ date_time: DateTime.new(2020) })
    }

    it {
      expect(mapper.cast({ 'date_time' => Time.new(2020) })).to eq({ date_time: Time.new(2020).to_datetime })
    }

    it {
      expect(mapper.cast({ 'date_time' => DateTime.new(2020).to_s })).to eq({ date_time: DateTime.new(2020) })
    }

    it {
      expect(mapper.cast({ 'date_time' => '2020-01-01' })).to eq({ date_time: DateTime.new(2020) })
    }

    it {
      expect { mapper.cast({ 'date_time' => Date.new(2020) }) }.to raise_error(ReeMapper::TypeError, "`date_time` should be a datetime")
    }

    it {
      expect { mapper.cast({ 'date_time' => Object.new }) }.to raise_error(ReeMapper::TypeError, "`date_time` should be a datetime")
    }

    it {
      expect { mapper.cast({ 'date_time' => 'no date time' }) }.to raise_error(ReeMapper::CoercionError, "`date_time` is invalid datetime")
    }
  end

  describe '#db_dump' do
    it {
      expect(mapper.db_dump OpenStruct.new({ date_time: DateTime.new(2020) })).to eq({ date_time: DateTime.new(2020) })
    }

    it {
      expect { mapper.db_dump OpenStruct.new({ date_time: Time.new(2020) }) }.to raise_error(ReeMapper::TypeError, "`date_time` should be a datetime")
    }

    it {
      expect { mapper.db_dump OpenStruct.new({ date_time: Date.new(2020) }) }.to raise_error(ReeMapper::TypeError, "`date_time` should be a datetime")
    }

    it {
      expect { mapper.db_dump OpenStruct.new({ date_time: DateTime.new(2020).to_s }) }.to raise_error(ReeMapper::TypeError, "`date_time` should be a datetime")
    }

    it {
      expect { mapper.db_dump OpenStruct.new({ date_time: '2020-01-01' }) }.to raise_error(ReeMapper::TypeError, "`date_time` should be a datetime")
    }

    it {
      expect { mapper.db_dump OpenStruct.new({ date_time: Object.new }) }.to raise_error(ReeMapper::TypeError, "`date_time` should be a datetime")
    }
  end

  describe '#db_load' do
    it {
      expect(mapper.db_load({ 'date_time' => DateTime.new(2020) })).to eq({ date_time: DateTime.new(2020) })
    }

    it {
      expect(mapper.db_load({ 'date_time' => Time.new(2020) })).to eq({ date_time: Time.new(2020).to_datetime })
    }

    it {
      expect(mapper.db_load({ 'date_time' => DateTime.new(2020).to_s })).to eq({ date_time: DateTime.new(2020) })
    }

    it {
      expect(mapper.db_load({ 'date_time' => '2020-01-01' })).to eq({ date_time: DateTime.new(2020) })
    }

    it {
      expect { mapper.db_load({ 'date_time' => Date.new(2020) }) }.to raise_error(ReeMapper::TypeError, "`date_time` should be a datetime")
    }

    it {
      expect { mapper.db_load({ 'date_time' => Object.new }) }.to raise_error(ReeMapper::TypeError, "`date_time` should be a datetime")
    }

    it {
      expect { mapper.db_load({ 'date_time' => 'no date time' }) }.to raise_error(ReeMapper::CoercionError, "`date_time` is invalid datetime")
    }
  end
end
