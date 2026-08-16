# frozen_string_literal: true
require 'benchmark'

package_require "ree_mapper"
package_require "ree_dto/entity_dsl"

# Run with:
#   REE_BENCHMARK=1 bundle exec rspec ... db_load_benchmark_spec.rb
# Contracts state is fixed at method definition time, so measure both setups
# in separate processes: a plain run (contracts on) and NO_CONTRACTS=1.
RSpec.public_send(ENV["REE_BENCHMARK"] ? :describe : :xdescribe, 'db_load performance mode benchmark') do
  link :build_mapper_factory, from: :ree_mapper
  link :build_mapper_strategy, from: :ree_mapper

  after { Ree.disable_db_load_performance_mode }

  ROWS_COUNT = 10_000
  REPS = 10

  class DbLoadBenchDto
    include ReeDto::DSL

    build_dto do
      field :id, Integer
      field :num2, Integer
      field :num3, Integer
      field :num4, Integer
      field :num5, Integer
      field :name, String
      field :s2, String
      field :s3, String
      field :s4, String
      field :s5, String
      field :active, Bool
      field :flag2, Bool
      field :score, Float
      field :score2, Float
      field :born_on, Date
      field :born2, Date
      field :seen_at, Time
      field :seen2, Time
      field :registered_at, DateTime
      field :payload, Any
    end
  end

  class DbLoadBenchEntity
    include ReeDto::EntityDSL

    properties(
      id: Nilor[Integer], num2: Nilor[Integer], num3: Nilor[Integer],
      num4: Nilor[Integer], num5: Nilor[Integer],
      name: Nilor[String], s2: Nilor[String], s3: Nilor[String],
      s4: Nilor[String], s5: Nilor[String],
      active: Nilor[Bool], flag2: Nilor[Bool],
      score: Nilor[Float], score2: Nilor[Float],
      born_on: Nilor[Date], born2: Nilor[Date],
      seen_at: Nilor[Time], seen2: Nilor[Time],
      registered_at: Nilor[DateTime], payload: Any,
    )
  end

  wide_blk = Proc.new do
    integer :id
    integer :num2
    integer :num3
    integer :num4
    integer :num5
    string :name
    string :s2
    string :s3
    string :s4
    string :s5
    bool :active
    bool :flag2
    float :score
    float :score2
    date :born_on
    date :born2
    time :seen_at
    time :seen2
    date_time :registered_at
    any :payload
  end

  mixed_blk = Proc.new do
    integer :id
    string :name
    bool :active
    date :born_on
    hash :meta, null: true do
      date :day
      integer :num
    end
    array :nums, integer, null: true
  end

  def build_mapper_with_mode(mode_on, dto, blk)
    mode_on ? Ree.enable_db_load_performance_mode : Ree.disable_db_load_performance_mode

    build_mapper_factory(
      strategies: [
        build_mapper_strategy(method: :db_load, dto: dto, always_optional: true)
      ]
    ).call.use(:db_load, dto: dto, &blk)
  ensure
    Ree.disable_db_load_performance_mode
  end

  def wide_rows
    Array.new(ROWS_COUNT) do |i|
      {
        id: i, num2: i, num3: i, num4: i, num5: i,
        name: "name-#{i}", s2: "a", s3: "b", s4: "c", s5: "d",
        active: true, flag2: false,
        score: 1.5, score2: 2.5,
        born_on: Date.new(2020, 1, 1), born2: Date.new(2021, 2, 2),
        seen_at: Time.at(i).utc, seen2: Time.at(i * 2).utc,
        registered_at: DateTime.new(2020, 1, 1, 12, 0, 0),
        payload: { x: i },
      }
    end
  end

  def mixed_rows
    Array.new(ROWS_COUNT) do |i|
      {
        id: i, name: "name-#{i}", active: true, born_on: Date.new(2020, 1, 1),
        meta: { day: "2020-01-01", num: i }, # string date: the JSONB guard-fallback path
        nums: [1, 2, 3],
      }
    end
  end

  def report_alloc(label, rows, mapper)
    GC.start
    allocated_before = GC.stat(:total_allocated_objects)
    gc_before = GC.count
    rows.each { mapper.db_load(_1) }
    allocated = GC.stat(:total_allocated_objects) - allocated_before
    gc_runs = GC.count - gc_before
    puts format("%-28s %10d objects, %3d GC runs per %d rows", label, allocated, gc_runs, rows.size)
  end

  it 'wide primitive row: generic vs compiled' do
    rows = wide_rows

    pairs = {
      "hash dto" => [
        build_mapper_with_mode(false, Hash, wide_blk),
        build_mapper_with_mode(true, Hash, wide_blk),
      ],
      "ree_dto" => [
        build_mapper_with_mode(false, DbLoadBenchDto, wide_blk),
        build_mapper_with_mode(true, DbLoadBenchDto, wide_blk),
      ],
      "entity_dsl" => [
        build_mapper_with_mode(false, DbLoadBenchEntity, wide_blk),
        build_mapper_with_mode(true, DbLoadBenchEntity, wide_blk),
      ],
    }

    puts "\ncontracts: #{Ree::Contracts.no_contracts? ? 'OFF (NO_CONTRACTS)' : 'ON'}"

    Benchmark.bmbm do |x|
      pairs.each do |name, (generic, compiled)|
        x.report("generic  #{name}") { REPS.times { rows.each { generic.db_load(_1) } } }
        x.report("compiled #{name}") { REPS.times { rows.each { compiled.db_load(_1) } } }
      end
    end

    puts "\nallocations:"
    pairs.each do |name, (generic, compiled)|
      report_alloc("generic  #{name}", rows, generic)
      report_alloc("compiled #{name}", rows, compiled)
    end
  end

  it 'mixed row with nested hash and array: generic vs compiled' do
    rows = mixed_rows
    generic = build_mapper_with_mode(false, DbLoadBenchDto, mixed_blk)
    compiled = build_mapper_with_mode(true, DbLoadBenchDto, mixed_blk)

    Benchmark.bmbm do |x|
      x.report("generic  mixed") { REPS.times { rows.each { generic.db_load(_1) } } }
      x.report("compiled mixed") { REPS.times { rows.each { compiled.db_load(_1) } } }
    end

    puts "\nallocations:"
    report_alloc("generic  mixed", rows, generic)
    report_alloc("compiled mixed", rows, compiled)
  end
end

# Results (2026-08-16, Ruby 4.0.1, 10_000 rows x 10 reps, real seconds):
#
# contracts: ON
#                            generic    compiled   speedup
#   wide (20 fields) hash      60.53s      0.41s     ~149x
#   wide ree_dto               74.76s      0.43s     ~174x
#   wide entity_dsl            63.78s      0.36s     ~175x
#   mixed (jsonb-like)         37.23s      5.43s     ~6.9x
#
#   allocations per 10_000 rows:
#   wide hash        15_820_000 -> 10_000      wide ree_dto  18_350_000 -> 20_000
#   wide entity_dsl  15_820_000 -> 10_000      mixed          8_930_000 -> 1_190_000
#   GC runs: 40-46 -> 0 (wide), 72 -> 9 (mixed)
#
# contracts: OFF (NO_CONTRACTS=1)
#                            generic    compiled   speedup
#   wide (20 fields) hash       2.54s      0.42s     ~6.0x
#   wide ree_dto                2.77s      0.43s     ~6.4x
#   wide entity_dsl             2.43s      0.39s     ~6.2x
#   mixed (jsonb-like)          2.52s      1.21s     ~2.1x
#
#   allocations per 10_000 rows:
#   wide hash        220_000 -> 10_000          wide ree_dto  260_000 -> 20_000
#   wide entity_dsl  220_000 -> 10_000          mixed         360_000 -> 200_000
