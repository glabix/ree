# frozen_string_literal: true
require 'benchmark'

no_contracts = Ree::Contracts.no_contracts?
Ree.disable_contracts

package_require "ree_mapper"

RSpec.xdescribe 'Mapper Benchmark' do
  link :build_mapper_factory, from: :ree_mapper
  link :build_mapper_strategy, from: :ree_mapper

  let(:mapper) do
    build_mapper_factory(
      strategies: [
        build_mapper_strategy(method: :cast, dto: Hash),
      ]
    ).call.use(:cast) do
      hash :my_field do
        hash :my_field do
          integer :my_field
        end
      end
    end
  end

  it do
    obj = { my_field: { my_field: { my_field: 1 } } }

    _benchmark_res = Benchmark.bmbm do |x|
      x.report('cast') { 100000.times { mapper.cast(obj) } }
    end
  end

  xit do
    Ree.disable_contracts
    require "ruby-prof"
    package_require "ree_mapper"

    mapper = ReeMapper::BuildMapperFactory.new.call(
      strategies: [
        ReeMapper::BuildMapperStrategy.new.call(method: :cast, dto: Hash),
      ]
    ).call.use(:cast) do
      hash :my_field do
        hash :my_field do
          integer :my_field
        end
      end
    end

    obj = { my_field: { my_field: { my_field: 1 } } }

    result = RubyProf::Profile.profile do
      mapper.cast(obj)
    end

    RubyProf::FlatPrinter.new(result).print(STDOUT)
  end
end

if !no_contracts
  Ree.enable_contracts
end

# version main
# cast   0.625590   0.008543   0.634133 (  0.635625)
# cast   0.589163   0.003962   0.593125 (  0.593500)
# version 1.0.93
# cast   0.791664   0.004125   0.795789 (  0.796938)
# cast   0.782544   0.016745   0.799289 (  0.799759)
