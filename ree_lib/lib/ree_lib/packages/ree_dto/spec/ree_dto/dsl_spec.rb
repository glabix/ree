# frozen_string_literal: true
package_require("ree_dto/dsl")

RSpec.describe ReeDto::DSL do
  class DtoClass
    include ReeDto::DSL

    build_dto do
      field :with_default, Nilor[Integer], default: 1
      field :string, String
      field :without_setter, Integer, setter: false
    end
  end

  it {
    dto = DtoClass.new
    expect(dto.with_default).to eq(1)

    dto = DtoClass.new({})
    expect(dto.with_default).to eq(1)
    expect(dto.get_value(:with_default)).to eq(1)
  }

  it {
    dto = DtoClass.new
    expect(dto.has_value?(:with_default)).to eq(true)
    expect(dto.has_value?(:string)).to eq(false)
  }

  it {
    dto = DtoClass.new({with_default: 1, string: "string", without_setter: 22})
    expect(dto.to_s).to include("DtoClass")
  }

  it {
    dto = DtoClass.new

    expect {
      dto.string
    }.to raise_error do |e|
      expect(e.message).to eq("field :string not set for DtoClass")
    end
  }

  it {
    dto = DtoClass.new(string: "string")
    expect(dto.string).to eq("string")

    dto.string = "changed"
    expect(dto.string).to eq("changed")
    expect(dto.changed_fields).to eq([:string])
  }

  it {
    dto = DtoClass.new
    fields = []
    values = []

    dto.each_field do |name, value|
      fields << name
      values << value
    end

    expect(fields).to eq([:with_default])
    expect(values).to eq([1])
  }
end