# frozen_string_literal: true
require 'bigdecimal'

RSpec.describe 'ReeMapper::Rational' do
  link :build_mapper_factory, from: :ree_mapper
  link :build_mapper_strategy, from: :ree_mapper

  let(:mapper_factory) {
    build_mapper_factory(
      strategies: [
        build_mapper_strategy(method: :cast, dto: Hash),
        build_mapper_strategy(method: :serialize, dto: Hash),
        build_mapper_strategy(method: :db_dump, dto: Hash),
        build_mapper_strategy(method: :db_load, dto: Hash)
      ]
    )
  }

  let(:mapper) {
    mapper_factory.call.use(:cast).use(:serialize).use(:db_dump).use(:db_load) {
      rational :rational
    }
  }

  describe '#cast' do
    it {
      expect(mapper.cast({ rational: Rational("1/3") })).to eq({ rational: Rational("1/3") })
    }

    it {
      expect(mapper.cast({ rational: 0.33 })).to eq({ rational: Rational(0.33) })
    }

    it {
      expect(mapper.cast({ rational: '0.33' })).to eq({ rational: Rational('0.33') })
    }

    it {
      expect(mapper.cast({ rational: BigDecimal("0.33") })).to eq({ rational: Rational(BigDecimal("0.33")) })
    }

    it {
      expect { mapper.cast({ rational: 'a333' }) }.to raise_error(ReeMapper::CoercionError, '`rational` is invalid rational')
    }

    it {
      expect { mapper.cast({ rational: '333a' }) }.to raise_error(ReeMapper::CoercionError, '`rational` is invalid rational')
    }

    it {
      expect { mapper.cast({ rational: Object.new }) }.to raise_error(ReeMapper::TypeError, "`rational` should be a rational")
    }
  end

  describe '#serialize' do
    it {
      expect(mapper.serialize({ rational: Rational("1/3") })).to eq({ rational: Rational("1/3") })
    }

    it {
      expect { mapper.serialize({ rational: '1/3' }) }.to raise_error(ReeMapper::TypeError, "`rational` should be a rational")
    }

    it {
      expect { mapper.serialize({ rational: nil }) }.to raise_error(ReeMapper::TypeError, "`rational` should be a rational")
    }

    it {
      expect { mapper.serialize({ rational: Object.new }) }.to raise_error(ReeMapper::TypeError, "`rational` should be a rational")
    }
  end

  describe '#db_dump' do
    it {
      expect(mapper.db_dump({ rational: Rational("1/3") })).to eq({ rational: "1/3" })
    }

    it {
      expect { mapper.db_dump({ rational: '1/3' }) }.to raise_error(ReeMapper::TypeError, "`rational` should be a rational")
    }

    it {
      expect { mapper.db_dump({ rational: nil }) }.to raise_error(ReeMapper::TypeError, "`rational` should be a rational")
    }

    it {
      expect { mapper.db_dump({ rational: Object.new }) }.to raise_error(ReeMapper::TypeError, "`rational` should be a rational")
    }
  end

  describe '#db_load' do
    it {
      expect(mapper.db_load({ rational: Rational("1/3") })).to eq({ rational: Rational("1/3") })
    }

    it {
      expect(mapper.db_load({ rational: 0.33 })).to eq({ rational: Rational(0.33) })
    }

    it {
      expect(mapper.db_load({ rational: '0.33' })).to eq({ rational: Rational('0.33') })
    }

    it {
      expect(mapper.db_load({ rational: BigDecimal("0.33") })).to eq({ rational: Rational(BigDecimal("0.33")) })
    }

    it {
      expect { mapper.db_load({ rational: 'a333' }) }.to raise_error(ReeMapper::CoercionError, '`rational` is invalid rational')
    }

    it {
      expect { mapper.db_load({ rational: '333a' }) }.to raise_error(ReeMapper::CoercionError, '`rational` is invalid rational')
    }

    it {
      expect { mapper.db_load({ rational: Object.new }) }.to raise_error(ReeMapper::TypeError, "`rational` should be a rational")
    }
  end
end
