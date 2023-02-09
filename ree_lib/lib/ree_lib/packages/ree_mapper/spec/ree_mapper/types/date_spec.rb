# frozen_string_literal: true

RSpec.describe 'ReeMapper::Date' do
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
      date :date
    }
  }

  describe '#serialize' do
    it {
      expect(mapper.serialize({ date: Date.new(2020) })).to eq({ date: Date.new(2020) })
    }

    it {
      expect { mapper.serialize({ date: DateTime.new(2020) }) }.to raise_error(ReeMapper::TypeError, "`date` should be a date")
    }

    it {
      expect { mapper.serialize({ date: Time.new(2020) }) }.to raise_error(ReeMapper::TypeError, "`date` should be a date")
    }

    it {
      expect { mapper.serialize({ date: '2020-01-01' }) }.to raise_error(ReeMapper::TypeError, "`date` should be a date")
    }

    it {
      expect { mapper.serialize({ date: Object.new }) }.to raise_error(ReeMapper::TypeError, "`date` should be a date")
    }
  end

  describe '#cast' do
    it {
      expect(mapper.cast({ 'date' => Date.parse('2022-02-02') })).to eq({ date: Date.parse('2022-02-02') })
    }

    it {
      expect(mapper.cast({ 'date' => DateTime.new(2020) })).to eq({ date: DateTime.new(2020).to_date })
    }

    it {
      expect(mapper.cast({ 'date' => Time.new(2020) })).to eq({ date: Time.new(2020).to_date })
    }

    it {
      expect(mapper.cast({ 'date' => '2022-02-02' })).to eq({ date: Date.parse('2022-02-02') })
    }

    it {
      expect { mapper.cast({ 'date' => 'no date' }) }.to raise_error(ReeMapper::CoercionError, "`date` is invalid date")
    }
  end

  describe '#db_load' do
    it {
      expect(mapper.db_load({ 'date' => Date.parse('2022-02-02') })).to eq({ date: Date.parse('2022-02-02') })
    }

    it {
      expect(mapper.db_load({ 'date' => DateTime.new(2020) })).to eq({ date: DateTime.new(2020).to_date })
    }

    it {
      expect(mapper.db_load({ 'date' => Time.new(2020) })).to eq({ date: Time.new(2020).to_date })
    }

    it {
      expect(mapper.db_load({ 'date' => '2022-02-02' })).to eq({ date: Date.parse('2022-02-02') })
    }

    it {
      expect { mapper.db_load({ 'date' => 'no date' }) }.to raise_error(ReeMapper::CoercionError, "`date` is invalid date")
    }
  end

  describe '#db_dump' do
    it {
      expect(mapper.db_dump OpenStruct.new({ date: Date.new(2020) })).to eq({ date: Date.new(2020) })
    }

    it {
      expect { mapper.db_dump OpenStruct.new({ date: DateTime.new(2020) }) }.to raise_error(ReeMapper::TypeError, "`date` should be a date")
    }

    it {
      expect { mapper.db_dump OpenStruct.new({ date: Time.new(2020) }) }.to raise_error(ReeMapper::TypeError, "`date` should be a date")
    }

    it {
      expect { mapper.db_dump OpenStruct.new({ date: '2020-01-01' }) }.to raise_error(ReeMapper::TypeError, "`date` should be a date")
    }

    it {
      expect { mapper.db_dump OpenStruct.new({ date: Object.new }) }.to raise_error(ReeMapper::TypeError, "`date` should be a date")
    }
  end
end
