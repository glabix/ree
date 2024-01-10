# frozen_string_literal: true

package_require("ree_dao/wrappers/pg_array")

RSpec.describe 'ReeDao::PgArray' do
  link :build_mapper_factory, from: :ree_mapper
  link :build_mapper_strategy, from: :ree_mapper

  let(:mapper_factory) {
    build_mapper_factory(
      strategies: [
        build_mapper_strategy(method: :cast),
        build_mapper_strategy(method: :serialize),
        build_mapper_strategy(method: :db_dump, dto: Hash),
        build_mapper_strategy(method: :db_load, dto: Hash, always_optional: true)
      ]
    ).register_wrapper(:pg_array, ReeDao::PgArray)
  }

  let(:mapper) {
    mapper_factory.call.use(:db_dump).use(:db_load) do
      pg_array? :tags, integer
      pg_array? :keys, string
    end
  }

  describe '#db_dump' do
    it {
      expect(mapper.db_dump({
        tags: [1, 2],
        keys: ["a", "b"]
      })).to eq({
        tags: [1, 2],
        keys: ["a", "b"]
      })
    }

    it {
      expect(mapper.db_dump({
        tags: []
      })).to eq({
        tags: "{}"
      })
    }

    it {
      expect {
        mapper.db_dump({ tags: 1 })
      }.to raise_error(ReeMapper::TypeError, "`tags` should be an array, got `1`")
    }
  end

  describe '#db_load' do
    it {
      expect(mapper.db_load({
        tags: Sequel::Postgres::PGArray.new([1, 2]),
        keys: Sequel::Postgres::PGArray.new(["a", "b"])
      })).to eq({
        tags: [1, 2],
        keys: ["a", "b"]
      })
    }

    it {
      expect {
        mapper.db_load({
          tags: 1
        })
      }.to raise_error(ReeMapper::TypeError, "`tags` should be a Sequel::Postgres::PGArray, got `1`")
    }
  end
end