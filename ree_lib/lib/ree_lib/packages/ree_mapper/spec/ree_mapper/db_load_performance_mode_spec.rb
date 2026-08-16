# frozen_string_literal: true
package_require "ree_mapper"
package_require "ree_dto/entity_dsl"

RSpec.describe "db_load performance mode" do
  link :build_mapper_factory, from: :ree_mapper
  link :build_mapper_strategy, from: :ree_mapper

  after do
    Ree.disable_db_load_performance_mode
  end

  class PerfModeDto
    include ReeDto::DSL

    build_dto do
      field :id, Integer
      field :name, String
    end
  end

  class PerfModeEntity
    include ReeDto::EntityDSL

    properties(
      id: Nilor[Integer],
      name: Nilor[String],
    )
  end

  def build_factory(dto:, always_optional: true)
    build_mapper_factory(
      strategies: [
        build_mapper_strategy(method: :db_load, dto: dto, always_optional: always_optional)
      ]
    )
  end

  # builds the same mapper twice: with the mode off (generic path) and on
  # (compiled path), so examples can assert identical behavior
  def build_pair(dto: Hash, always_optional: true, register_as: nil, &blk)
    Ree.disable_db_load_performance_mode
    generic = build_factory(dto: dto, always_optional: always_optional)
      .call(register_as: register_as).use(:db_load, dto: dto, &blk)

    Ree.enable_db_load_performance_mode
    compiled = build_factory(dto: dto, always_optional: always_optional)
      .call(register_as: register_as).use(:db_load, dto: dto, &blk)
    Ree.disable_db_load_performance_mode

    [generic, compiled]
  end

  def expect_same_result(generic, compiled, input, **opts)
    generic_result = begin; generic.db_load(input, **opts); rescue => e; e; end
    compiled_result = begin; compiled.db_load(input, **opts); rescue => e; e; end

    if generic_result.is_a?(Exception)
      expect(compiled_result.class).to eq(generic_result.class)
      expect(compiled_result.message).to eq(generic_result.message)
    else
      expect(compiled_result).to eq(generic_result)
    end

    compiled_result
  end

  wide_blk = Proc.new do
    integer :id
    string :name
    bool :active
    float :score, null: true
    date :born_on, null: true
    time :seen_at, null: true
    date_time :registered_at, null: true
    rational :ratio, null: true
    any :payload, null: true
    integer :renamed, from: :src
    string? :note, default: "-"
    integer? :maybe
    integer :admin_count, role: :admin
    hash :meta, null: true do
      date :day
      integer :num
    end
    array :nums, integer, null: true
  end

  def wide_row
    {
      id: 1,
      name: "n",
      active: true,
      score: 1.5,
      born_on: Date.new(2020, 1, 1),
      seen_at: Time.at(0).utc,
      registered_at: DateTime.new(2020, 1, 1, 12, 0, 0),
      ratio: Rational(1, 2),
      payload: { x: 1 },
      src: 5,
      note: "hi",
      maybe: 2,
      meta: { day: "2020-01-01", num: 3 },
      nums: [1, 2],
    }
  end

  it "compiles db_load when the mode is on and keeps the generic fallback" do
    _generic, compiled = build_pair(&wide_blk)

    expect(compiled.class.method_defined?(:__generic_db_load, false)).to be true
    expect(compiled.class.const_defined?(:DB_LOAD_FIELDS, false)).to be true
  end

  it "does not compile when the mode is off" do
    generic, _compiled = build_pair(&wide_blk)

    expect(generic.class.method_defined?(:__generic_db_load, false)).to be false
  end

  context "parity with the generic path" do
    it "loads a full row identically" do
      generic, compiled = build_pair(&wide_blk)
      result = expect_same_result(generic, compiled, wide_row)

      expect(result[:id]).to eq(1)
      expect(result[:renamed]).to eq(5)
      expect(result[:meta][:day]).to eq(Date.new(2020, 1, 1)) # JSONB-style string is still cast
      expect(result[:nums]).to eq([1, 2])
      expect(result.key?(:admin_count)).to be false
    end

    it "still coerces values that fail the type guard" do
      generic, compiled = build_pair(&wide_blk)
      result = expect_same_result(generic, compiled, wide_row.merge(id: "5", score: 2))

      expect(result[:id]).to eq(5)
      expect(result[:score]).to eq(2.0)
      expect(result[:score]).to be_a(Float)
    end

    it "raises the same error for nil in a null: false field" do
      generic, compiled = build_pair(&wide_blk)
      error = expect_same_result(generic, compiled, wide_row.merge(name: nil))

      expect(error).to be_a(ReeMapper::TypeError)
      expect(error.message).to include("`name`")
    end

    it "raises the same error for garbage that fails coercion" do
      generic, compiled = build_pair(&wide_blk)
      error = expect_same_result(generic, compiled, wide_row.merge(id: "abc"))

      expect(error).to be_a(ReeMapper::CoercionError)
      expect(error.message).to include("`id`")
    end

    it "raises the same error from a nested mapper with the field path" do
      generic, compiled = build_pair(&wide_blk)
      error = expect_same_result(generic, compiled, wide_row.merge(meta: { day: "not a date", num: 1 }))

      expect(error).to be_a(ReeMapper::CoercionError)
      expect(error.message).to include("`meta[day]`")
    end

    it "assigns nil without casting for null: true fields" do
      generic, compiled = build_pair(&wide_blk)
      result = expect_same_result(
        generic, compiled,
        wide_row.merge(score: nil, born_on: nil, meta: nil, nums: nil, payload: nil)
      )

      expect(result[:score]).to be_nil
      expect(result[:meta]).to be_nil
    end

    it "applies defaults and skips missing optional fields" do
      generic, compiled = build_pair(&wide_blk)
      row = wide_row
      row.delete(:note)
      row.delete(:maybe)
      result = expect_same_result(generic, compiled, row)

      expect(result[:note]).to eq("-")
      expect(result.key?(:maybe)).to be false
    end

    it "skips missing fields when the strategy is always_optional" do
      generic, compiled = build_pair(&wide_blk)
      result = expect_same_result(generic, compiled, { id: 1 })

      expect(result).to eq({ id: 1, note: "-" })
    end

    it "raises for missing required fields when the strategy is not always_optional" do
      generic, compiled = build_pair(always_optional: false) do
        integer :id
        string? :name
      end
      error = expect_same_result(generic, compiled, { name: "n" })

      expect(error).to be_a(ReeMapper::TypeError)
      expect(error.message).to include("`id` is missing (required field)")
    end

    it "supports string-keyed input" do
      generic, compiled = build_pair(&wide_blk)
      result = expect_same_result(generic, compiled, { "id" => 1, "name" => "n" })

      expect(result[:id]).to eq(1)
    end

    it "falls back to the generic path for non-Hash input" do
      generic, compiled = build_pair(&wide_blk)
      input = OpenStruct.new(id: 1, name: "n")
      result = expect_same_result(generic, compiled, input)

      expect(result[:id]).to eq(1)
    end

    it "falls back to the generic path for role calls" do
      generic, compiled = build_pair(&wide_blk)
      result = expect_same_result(generic, compiled, wide_row.merge(admin_count: 7), role: :admin)

      expect(result[:admin_count]).to eq(7)
    end

    it "falls back to the generic path for only/except calls" do
      generic, compiled = build_pair(&wide_blk)
      result = expect_same_result(generic, compiled, wide_row, only: [:id, :name])

      expect(result.keys).to contain_exactly(:id, :name)
    end

    it "respects field-level only filters on nested mappers" do
      generic, compiled = build_pair do
        integer :id
        hash :meta, null: true, only: [:num] do
          date :day, null: true
          integer :num
        end
      end
      result = expect_same_result(generic, compiled, { id: 1, meta: { day: "2020-01-01", num: 3 } })

      expect(result[:meta]).to eq({ num: 3 })
    end
  end

  context "dto outputs" do
    it "builds ree_dto entities" do
      generic, compiled = build_pair(dto: PerfModeDto) do
        integer :id
        string :name
      end

      generic_dto = generic.db_load({ id: 1, name: "n" })
      compiled_dto = compiled.db_load({ id: 1, name: "n" })

      expect(compiled_dto).to be_a(PerfModeDto)
      expect(compiled_dto.id).to eq(generic_dto.id)
      expect(compiled_dto.name).to eq(generic_dto.name)
      expect(compiled_dto.attrs).to eq(generic_dto.attrs)
    end

    it "builds entity_dsl objects via instance variables" do
      generic, compiled = build_pair(dto: PerfModeEntity) do
        integer :id
        string :name
      end

      generic_entity = generic.db_load({ id: 1, name: "n" })
      compiled_entity = compiled.db_load({ id: 1, name: "n" })

      expect(compiled_entity).to be_a(PerfModeEntity)
      expect(compiled_entity.id).to eq(generic_entity.id)
      expect(compiled_entity.name).to eq(generic_entity.name)
    end

    it "keeps the generic path for struct dto" do
      Ree.enable_db_load_performance_mode
      mapper = build_factory(dto: Struct).call.use(:db_load, dto: Struct) do
        integer :id
      end
      Ree.disable_db_load_performance_mode

      expect(mapper.class.method_defined?(:__generic_db_load, false)).to be false
      expect(mapper.db_load({ id: 1 }).id).to eq(1)
    end
  end

  context "registered (frozen) mappers" do
    it "compiles mappers registered via register_as" do
      generic, compiled = build_pair(register_as: :perf_mode_frozen, &wide_blk)

      expect(compiled.frozen?).to be true
      expect(compiled.class.method_defined?(:__generic_db_load, false)).to be true
      expect_same_result(generic, compiled, wide_row)
    end
  end

  describe "guard/cast identity invariant" do
    {
      ReeMapper::Integer => [1, -5, 10**20],
      ReeMapper::String => ["s", ""],
      ReeMapper::Bool => [true, false],
      ReeMapper::Float => [1.5, -0.0],
      ReeMapper::Date => [Date.new(2020, 1, 1)],
      ReeMapper::Time => [Time.at(0).utc],
      ReeMapper::DateTime => [DateTime.new(2020, 1, 1)],
      ReeMapper::Rational => [Rational(1, 2)],
      ReeMapper::Any => [1, "s", nil, [1], { a: 1 }],
    }.each do |type_class, values|
      it "#{type_class}: guard implies db_load is identity" do
        type = type_class.new
        check = type.db_load_trusted_check("v")

        values.each do |v|
          expect(eval(check)).to be(true), "guard rejected #{v.inspect} for #{type_class}"
          expect(type.db_load(v)).to equal(v)
        end
      end
    end

    it "guards reject values that db_load would convert" do
      {
        ReeMapper::Integer.new => "5",
        ReeMapper::Float.new => 2,
        ReeMapper::Date.new => DateTime.new(2020, 1, 1),
        ReeMapper::Time.new => DateTime.new(2020, 1, 1),
        ReeMapper::DateTime.new => Time.at(0).utc,
        ReeMapper::Rational.new => "1/2",
        ReeMapper::Bool.new => 1,
      }.each do |type, v|
        check = type.db_load_trusted_check("v")
        expect(eval(check)).to be(false), "guard accepted #{v.inspect} for #{type.class}"
      end
    end
  end
end
