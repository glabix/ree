# frozen_string_literal: true
package_require("ree_dto/dsl")

RSpec.describe "ReeDto build_from_attrs" do
  class ReeDto::BuildFromAttrsDto
    include ReeDto::DSL

    build_dto do
      field :id, Integer
      field :name, Nilor[String]
      field :with_default, Nilor[Integer], default: 7
    end
  end

  it "takes ownership of the attrs hash without copying" do
    attrs = { id: 1, name: "n" }
    dto = ReeDto::BuildFromAttrsDto.build_from_attrs(attrs)

    expect(dto.attrs).to equal(attrs)
    expect(dto.id).to eq(1)
    expect(dto.name).to eq("n")
  end

  it "fills defaults only for absent keys" do
    dto = ReeDto::BuildFromAttrsDto.build_from_attrs({ id: 1 })
    expect(dto.with_default).to eq(7)

    dto = ReeDto::BuildFromAttrsDto.build_from_attrs({ id: 1, with_default: nil })
    expect(dto.get_value(:with_default)).to eq(nil)
  end

  it "matches build for identical inputs" do
    built = ReeDto::BuildFromAttrsDto.build({ id: 1, name: "n" })
    fast = ReeDto::BuildFromAttrsDto.build_from_attrs({ id: 1, name: "n" })

    expect(fast.attrs).to eq(built.attrs)
    expect(fast).to eq(built)
  end

  it "produces a fully functional dto" do
    dto = ReeDto::BuildFromAttrsDto.build_from_attrs({ id: 1 })

    dto.name = "x"
    expect(dto.changed_fields).to eq([:name])
    expect(dto.has_value?(:name)).to be true
    expect(dto.to_h).to eq({ id: 1, name: "x", with_default: 7 })
  end
end
