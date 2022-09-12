# frozen_string_literal: true

RSpec.describe 'ReeMapper::MapperFactory type options' do
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

  describe 'from:' do
    let(:mapper) {
      mapper_factory.call.use(:cast).use(:serialize).use(:db_dump).use(:db_load) {
        integer :number, from: :from_number
      }
    }

    it {
      expect(mapper.cast({ from_number: 1 })).to eq({ number: 1 })
    }
  end

  describe 'optional:' do
    let(:mapper) {
      mapper_factory.call.use(:cast).use(:serialize).use(:db_dump).use(:db_load) {
        integer :number
        integer? :opt_number
        integer :opt_number_long, optional: true
        array? :opt_array, each: integer
        array? :opt_array_with_blk do
          integer :id
        end
        hash? :optional_hsh do
          integer :id
        end
      }
    }

    it {
      expect(mapper.cast({ number: 1, opt_number: 1, opt_number_long: 1 }))
        .to eq({ number: 1, opt_number: 1, opt_number_long: 1 })
    }

    it {
      expect(mapper.cast({ number: 1, opt_number: 1 })).to eq({ number: 1, opt_number: 1 })
    }

    it {
      expect(mapper.cast({ number: 1, opt_number_long: 1 })).to eq({ number: 1, opt_number_long: 1 })
    }

    it {
      expect { mapper.cast({}) }.to raise_error(ReeMapper::TypeError)
    }

    it {
      expect(mapper.cast({ number: 1, opt_array: [1] })).to eq({ number: 1, opt_array: [1] })
    }

    it {
      expect(mapper.cast({ number: 1, opt_array_with_blk: [{ id: 1 }] })).to eq({ number: 1, opt_array_with_blk: [{ id: 1 }] })
    }

    it {
      expect(mapper.cast({ number: 1, optional_hsh: { id: 1 } })).to eq({ number: 1, optional_hsh: { id: 1 } })
    }
  end

  describe 'null:' do
    let(:mapper) {
      mapper_factory.call.use(:cast).use(:serialize).use(:db_dump).use(:db_load) {
        integer :number
        integer :number_or_nil, null: true
      }
    }

    it {
      expect(mapper.cast({ number: 1, number_or_nil: 1 })).to eq({ number: 1, number_or_nil: 1 })
    }

    it {
      expect(mapper.cast({ number: 1, number_or_nil: nil })).to eq({ number: 1, number_or_nil: nil })
    }

    it {
      expect { mapper.cast({ number: nil, number_or_nil: 1 }) }.to raise_error(ReeMapper::TypeError)
    }
  end

  describe 'doc:' do
    let(:mapper) {
      mapper_factory.call.use(:cast).use(:serialize).use(:db_dump).use(:db_load) {
        integer :number, doc: 'Number'
      }
    }

    # TODO spec for doc
    it {
      expect(mapper.cast({ number: 1 })).to eq({ number: 1 })
    }
  end

  describe 'role:' do
    let(:mapper) {
      mapper_factory.call.use(:cast) {
        integer :for_all
        integer :for_admin, role: :admin
        integer :for_admin_or_moderator, role: [:admin, :moderator]
      }
    }

    it {
      expect(mapper.cast({ for_all: 1, for_admin: 1, for_admin_or_moderator: 1 })).to eq({ for_all: 1 })
    }

    it {
      expect(mapper.cast({ for_all: 1, for_admin: 1, for_admin_or_moderator: 1 }, role: :customer)).to eq({ for_all: 1 })
    }

    it {
      expect(mapper.cast({ for_all: 1, for_admin: 1, for_admin_or_moderator: 1 }, role: :admin)).to eq({ for_all: 1, for_admin: 1, for_admin_or_moderator: 1 })
    }

    it {
      expect(mapper.cast({ for_all: 1, for_admin: 1, for_admin_or_moderator: 1 }, role: :moderator)).to eq({ for_all: 1, for_admin_or_moderator: 1 })
    }

    it {
      expect(mapper.cast({ for_all: 1, for_admin: 1, for_admin_or_moderator: 1 }, role: [:customer, :moderator])).to eq({ for_all: 1, for_admin_or_moderator: 1 })
    }

    context 'with nested type' do
      let(:mapper) {
        mapper_factory.call(register_as: :nested_type).use(:cast) {
          integer :for_all
          integer :for_admin, role: :admin
        }
        
        mapper_factory.call.use(:cast) {
          nested_type :my_field
        }
      }

      it {
        expect(mapper.cast({ my_field: { for_all: 1, for_admin: 1 } })).to eq({ my_field: { for_all: 1 } })
      }

      it {
        expect(mapper.cast({ my_field: { for_all: 1, for_admin: 1 } }, role: :admin)).to eq({ my_field: { for_all: 1, for_admin: 1 } })
      }
    end
  end

  describe 'default:' do
    let(:mapper) { mapper_factory.call.use(:cast) { integer? :number, default: 0 } }

    it {
      expect(mapper.cast({ number: 1 })).to eq({ number: 1 })
    }

    it {
      expect(mapper.cast({})).to eq({ number: 0 })
    }

    it {
      expect { mapper.cast({ number: nil }) }.to raise_error(ReeMapper::TypeError, 'should be an integer')
    }

    it {
      expect {
        mapper_factory.call.use(:cast) { integer :number, default: 0 }
      }.to raise_error(ArgumentError)
    }

    context 'with invalid default value' do
      let(:mapper) { mapper_factory.call.use(:cast) { integer? :number, default: :not_number } }

      it {
        expect { mapper.cast({}) }.to raise_error(ReeMapper::TypeError, 'should be an integer')
      }
    end
  end
end
