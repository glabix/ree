# frozen_string_literal: true
require 'benchmark'

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
      x.report('cast') { 1000.times { mapper.cast(obj) } }
    end
  end
end
