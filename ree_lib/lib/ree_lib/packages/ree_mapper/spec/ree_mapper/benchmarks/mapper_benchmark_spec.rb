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

  xit do
    obj = { my_field: { my_field: { my_field: 1 } } }

    _benchmark_res = Benchmark.bmbm do |x|
      x.report('cast') { 100000.times { mapper.cast(obj) } }
    end
  end

  it do
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

# version 1.0.88
# cast   0.793431   0.000000   0.793431 (  0.793516)