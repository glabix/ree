# frozen_string_literal: true

RSpec.describe 'ReeMapper::String' do
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
      string :str
    }
  }

  describe '#serialize' do
    it { expect(mapper.serialize({ str: 'str' })).to eq({ str: 'str' }) }

    it { expect { mapper.serialize({ str: nil }) }.to raise_error(ReeMapper::TypeError, "`str` should be a string") }

    it { expect { mapper.serialize({ str: :sym }) }.to raise_error(ReeMapper::TypeError, "`str` should be a string") }

    it { expect { mapper.serialize({ str: Object.new }) }.to raise_error(ReeMapper::TypeError, "`str` should be a string") }
  end

  describe '#cast' do
    it { expect(mapper.cast({ str: 'str' })).to eq({ str: 'str' }) }

    it { expect { mapper.cast({ str: nil }) }.to raise_error(ReeMapper::TypeError, "`str` should be a string") }

    it { expect { mapper.cast({ str: :sym }) }.to raise_error(ReeMapper::TypeError, "`str` should be a string") }

    it { expect { mapper.cast({ str: Object.new }) }.to raise_error(ReeMapper::TypeError, "`str` should be a string") }
  end

  describe '#db_dump' do
    it { expect(mapper.db_dump({ str: 'str' })).to eq({ str: 'str' }) }

    it { expect { mapper.db_dump({ str: nil }) }.to raise_error(ReeMapper::TypeError, "`str` should be a string") }

    it { expect { mapper.db_dump({ str: :sym }) }.to raise_error(ReeMapper::TypeError, "`str` should be a string") }

    it { expect { mapper.db_dump({ str: Object.new }) }.to raise_error(ReeMapper::TypeError, "`str` should be a string") }
  end

  describe '#db_load' do
    it { expect(mapper.db_load({ str: 'str' })).to eq({ str: 'str' }) }

    it { expect { mapper.db_load({ str: nil }) }.to raise_error(ReeMapper::TypeError, "`str` should be a string") }

    it { expect { mapper.db_load({ str: :sym }) }.to raise_error(ReeMapper::TypeError, "`str` should be a string") }

    it { expect { mapper.db_load({ str: Object.new }) }.to raise_error(ReeMapper::TypeError, "`str` should be a string") }
  end
end
