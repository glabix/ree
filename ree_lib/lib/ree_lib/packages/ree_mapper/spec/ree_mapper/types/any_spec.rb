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
      any :any
    }
  }

  describe '#serialize' do
    it {
      expect(mapper.serialize({ any: true })).to eq({ any: true })
    }
  end

  describe '#cast' do
    it {
      expect(mapper.cast({ 'any' => true })).to eq({ any: true })
    }
  end

  describe '#db_dump' do
    it {
      expect(mapper.db_dump(OpenStruct.new({ any: true }))).to eq({ any: true })
    }
  end

  describe '#db_load' do
    it {
      expect(mapper.db_load({ 'any' => true })).to eq({ any: true })
    }
  end
end
