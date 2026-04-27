# frozen_string_literal: true

package_require("ree_dao/wrappers/pg_jsonb")

RSpec.describe 'ReeDao::PgJsonb' do
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
    ).register_wrapper(:pg_jsonb, ReeDao::PgJsonb)
  }

  let(:mapper) {
    mapper_factory.call.use(:db_dump).use(:db_load) do
      pg_jsonb? :payload do
        string :key
      end
      pg_jsonb? :numbers, array(integer)
      pg_jsonb? :figures, (array do
        string :coords
      end)
      pg_jsonb? :number, integer
      pg_jsonb? :boolean, bool
      pg_jsonb? :any, any
      pg_jsonb? :rational, rational
    end
  }

  describe '#db_dump' do
    it {
      expect(mapper.db_dump({
        payload: { key: 'key' },
        numbers: [1, 2],
        figures: [{ coords: 'x=1,y=1' }],
        number: 1,
        boolean: true,
        rational: Rational("1/3"),
      })).to eq({
        payload: { key: 'key' },
        numbers: [1, 2],
        figures: [{ coords: 'x=1,y=1' }],
        number: 1,
        boolean: true,
        rational: "1/3",
      })
    }

    it {
      expect {
        mapper.db_dump({ numbers: ['1'] })
      }.to raise_error(ReeMapper::TypeError, /`numbers\[0\]` should be an integer, got `\"1\"`/)
    }

    it {
      object = Object.new
      expect {
        mapper.db_dump({ any: object })
      }.to raise_error(ReeMapper::TypeError, /`any` should be an jsonb primitive, got `#{object.inspect}`/)
    }
  end

  describe '#db_load' do
    it {
      expect(mapper.db_load({
        payload: Sequel::Postgres::JSONBHash.new({ key: 'key' }),
        numbers: Sequel::Postgres::JSONBArray.new([1, 2]),
        figures: Sequel::Postgres::JSONBArray.new([{ coords: 'x=1,y=1' }]),
        number: 1,
        boolean: true,
        rational: "1/3"
      })).to eq({
        payload: { key: 'key' },
        numbers: [1, 2],
        figures: [{ coords: 'x=1,y=1' }],
        number: 1,
        boolean: true,
        rational: Rational("1/3"),
      })
    }

    it {
      expect {
        mapper.db_load({ numbers: Sequel::Postgres::JSONBArray.new([1.1]) })
      }.to raise_error(ReeMapper::TypeError, /`numbers\[0\]` should be an integer, got `1.1`/)
    }

    it {
      object = Object.new
      expect {
        mapper.db_load({ numbers: object })
      }.to raise_error(ReeMapper::TypeError, /`numbers` should be a Sequel::Postgres::JSONB, got `#{object.inspect}`/)
    }
  end

  describe 'restrict: with access_type' do
    let(:mapper) {
      mapper_factory.call.use(:db_dump).use(:db_load) do
        pg_jsonb :payload do
          integer :id
          string :email, restrict: [:visitor]
          string :phone, restrict: [:visitor, :guest]
        end
      end
    }

    let(:payload) {
      { payload: { id: 1, email: 'a@b.c', phone: '123' } }
    }

    describe '#db_dump' do
      it 'passes values through when no access_type given' do
        expect(mapper.db_dump(payload)).to eq({
          payload: Sequel.pg_jsonb_wrap({ id: 1, email: 'a@b.c', phone: '123' })
        })
      end

      it 'passes values through when access_type does not match any restrict' do
        expect(mapper.db_dump(payload, access_type: :admin)).to eq({
          payload: Sequel.pg_jsonb_wrap({ id: 1, email: 'a@b.c', phone: '123' })
        })
      end

      it 'filters fields whose restrict list includes the access_type' do
        expect(mapper.db_dump(payload, access_type: :guest)).to eq({
          payload: Sequel.pg_jsonb_wrap({ id: 1, email: 'a@b.c', phone: '[FILTERED]' })
        })
      end

      it 'filters all matching restricted fields when access_type matches' do
        expect(mapper.db_dump(payload, access_type: :visitor)).to eq({
          payload: Sequel.pg_jsonb_wrap({ id: 1, email: '[FILTERED]', phone: '[FILTERED]' })
        })
      end
    end

    describe '#db_load' do
      let(:loaded_payload) {
        { payload: Sequel::Postgres::JSONBHash.new({ id: 1, email: 'a@b.c', phone: '123' }) }
      }

      it 'passes values through when no access_type given' do
        expect(mapper.db_load(loaded_payload)).to eq(payload)
      end

      it 'passes values through when access_type does not match any restrict' do
        expect(mapper.db_load(loaded_payload, access_type: :admin)).to eq(payload)
      end

      it 'filters fields whose restrict list includes the access_type' do
        expect(mapper.db_load(loaded_payload, access_type: :guest)).to eq({
          payload: { id: 1, email: 'a@b.c', phone: '[FILTERED]' }
        })
      end

      it 'filters all matching restricted fields when access_type matches' do
        expect(mapper.db_load(loaded_payload, access_type: :visitor)).to eq({
          payload: { id: 1, email: '[FILTERED]', phone: '[FILTERED]' }
        })
      end
    end
  end
end
