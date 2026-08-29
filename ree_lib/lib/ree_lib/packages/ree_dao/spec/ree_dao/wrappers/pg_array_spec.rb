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
      }.to raise_error(ReeMapper::TypeError, /`tags` should be an array, got `1`/)
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
      }.to raise_error(ReeMapper::TypeError, /`tags` should be a Sequel::Postgres::PGArray, got `1`/)
    }
  end

  describe 'restrict: with access_type' do
    let(:mapper) {
      mapper_factory.call(register_as: :pg_array_user).use(:db_dump).use(:db_load) {
        integer :id
        string :email, restrict: [:visitor]
      }

      mapper_factory.call.use(:db_dump).use(:db_load) do
        pg_array :users, pg_array_user
      end
    }

    let(:payload) {
      { users: [{ id: 1, email: 'a@b.c' }, { id: 2, email: 'c@d.e' }] }
    }

    describe '#db_dump' do
      it 'passes values through when no access_type given' do
        expect(mapper.db_dump(payload)).to eq({ users: Sequel.pg_array(payload[:users]) })
      end

      it 'passes values through when access_type does not match any restrict' do
        expect(mapper.db_dump(payload, access_type: :admin)).to eq({ users: Sequel.pg_array(payload[:users]) })
      end

      it 'filters restricted fields of every element when access_type matches' do
        expect(mapper.db_dump(payload, access_type: :visitor)).to eq({
          users: Sequel.pg_array([
            { id: 1, email: '[FILTERED]' },
            { id: 2, email: '[FILTERED]' }
          ])
        })
      end
    end

    describe '#db_load' do
      let(:loaded_payload) {
        { users: Sequel::Postgres::PGArray.new([{ id: 1, email: 'a@b.c' }, { id: 2, email: 'c@d.e' }]) }
      }

      it 'passes values through when no access_type given' do
        expect(mapper.db_load(loaded_payload)).to eq(payload)
      end

      it 'passes values through when access_type does not match any restrict' do
        expect(mapper.db_load(loaded_payload, access_type: :admin)).to eq(payload)
      end

      it 'filters restricted fields of every element when access_type matches' do
        expect(mapper.db_load(loaded_payload, access_type: :visitor)).to eq({
          users: [
            { id: 1, email: '[FILTERED]' },
            { id: 2, email: '[FILTERED]' }
          ]
        })
      end
    end
  end
end
