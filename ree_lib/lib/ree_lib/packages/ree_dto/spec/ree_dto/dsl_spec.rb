# frozen_string_literal: true
package_require("ree_dto/dsl")

RSpec.describe ReeDto::DSL do
  class ReeDto::DtoClass
    include ReeDto::DSL

    User = Struct.new(:id, :name, :status)

    build_dto do
      field :with_default, Nilor[Integer], default: 1
      field :string, String
      field :without_setter, Integer, setter: false

      collection :numbers, Integer do
        filter :odd, -> { _1.odd? }

        def to_s
          "odd_collection"
        end
      end

      collection :active_users, User

      collection :users, User do
        filter :active, -> { _1.status == "active" }
        filter :inactive, -> { _1.status != "active" }
      end
    end
  end

  context "fields" do
    it {
      dto = ReeDto::DtoClass.new(string: "str")
      expect(dto.changed_fields).to eq([])
      dto.set_as_changed(:string)
      expect(dto.changed_fields).to eq([:string])
    }

    it {
      dto = ReeDto::DtoClass.new
      expect(dto.with_default).to eq(1)

      dto = ReeDto::DtoClass.new({})
      expect(dto.with_default).to eq(1)
      expect(dto.get_value(:with_default)).to eq(1)
    }

    it {
      dto = ReeDto::DtoClass.new
      expect(dto.has_value?(:with_default)).to eq(true)
      expect(dto.has_value?(:string)).to eq(false)
    }

    it {
      dto = ReeDto::DtoClass.new({with_default: 1, string: "string", without_setter: 22})
      expect(dto.to_s).to include("ReeDto::DtoClass")
    }

    it {
      dto = ReeDto::DtoClass.new

      expect {
        dto.string
      }.to raise_error do |e|
        expect(e.message).to eq("field `string` not set for: #<dto ReeDto::DtoClass with_default=1>")
      end
    }

    it {
      dto = ReeDto::DtoClass.new(string: "string")
      expect(dto.string).to eq("string")

      dto.string = "changed"
      expect(dto.string).to eq("changed")
      expect(dto.changed_fields).to eq([:string])
    }

    it {
      dto = ReeDto::DtoClass.new
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

  context "collections" do
    it {
      dto = ReeDto::DtoClass.new

      dto.numbers << 1
      dto.numbers << 2

      expect(dto.numbers.first).to eq(1)
      expect(dto.numbers.last).to eq(2)
      expect(dto.numbers.find { _1 == 1 }).to eq(1)
      expect(dto.numbers.class).to eq(ReeDto::DtoClass::NumbersCollectionDto)
      expect(dto.users.class).to eq(ReeDto::DtoClass::UsersCollectionDto)
      expect(dto.active_users.class).to eq(ReeDto::DtoClass::ActiveUsersCollectionDto)
      expect(dto.numbers.sum).to eq(3)
      expect(dto.numbers.to_s).to eq("odd_collection")
      dto.numbers.clear
      expect(dto.numbers.size).to eq(0)
    }

    it {
      dto = ReeDto::DtoClass.new

      dto.numbers = [1, 2, 3, 4]
      expect(dto.numbers.to_a).to eq([1, 2, 3, 4])
    }

    it {
      dto = ReeDto::DtoClass.new

      dto.users.push(ReeDto::DtoClass::User.new(1, "John", "active"))
      dto.users.push(ReeDto::DtoClass::User.new(1, "Adam", "inactive"))

      expect(dto.users.active.size).to eq(1)

      peter = ReeDto::DtoClass::User.new(1, "Peter", "active")
      dto.users.active << peter

      expect(dto.users.size).to eq(3)
      expect(dto.users.active.empty?).to eq(false)
      expect(dto.users.active.size).to eq(2)

      expect {
        dto.users.active << ReeDto::DtoClass::User.new(1, "John", "inactive")
      }.to raise_error(ReeDto::CollectionFilter::InvalidFilterItemErr)

      dto.users.active.remove(peter)
      expect(dto.users.size).to eq(2)
      expect(dto.users.active.size).to eq(1)
    }
  end

  describe "#==" do
    it {
      expect(
        ReeDto::DtoClass.new(string: "str")
      ).to eq(
        ReeDto::DtoClass.new(string: "str")
      )
    }

    it {
      expect(
        ReeDto::DtoClass.new(string: "str")
      ).to eq(
        ReeDto::DtoClass.new(string: "str", without_setter: 0)
      )
    }

    it {
      expect(
        ReeDto::DtoClass.new(string: "str")
      ).not_to eq(
        ReeDto::DtoClass.new(string: "str2")
      )
    }

    it {
      expect(
        ReeDto::DtoClass.new(string: "str")
      ).not_to eq(
        ReeDto::DtoClass.new(string: "str", with_default: 2)
      )
    }
  end

  describe "#to_h" do
    it {
      dto = ReeDto::DtoClass.new(string: "str")
      expect(dto.to_h).to eq({ string: "str", with_default: 1 })
    }
  end

  describe "#dup" do
    it {
      dto = ReeDto::DtoClass.new(string: "str")
      dto.string = "changed"
      expect(dto.changed_fields).to eq([:string])

      dup = dto.dup      
      expect(dup).to eq(dto)
      expect(dup.object_id).not_to eq(dto.object_id)
      expect(dup.changed_fields).to eq([])

      dup.string = "changed2"
      expect(dup).not_to eq(dto)

      dto.freeze
      expect(dto.dup.frozen?).to eq(false)
    }
  end

  describe "#clone" do
    it {
      dto = ReeDto::DtoClass.new(string: "str")
      dto.string = "changed"
      expect(dto.changed_fields).to eq([:string])

      clone = dto.clone
      expect(clone).to eq(dto)
      expect(clone.object_id).not_to eq(dto.object_id)
      expect(clone.changed_fields).to eq([:string])

      clone.string = "changed2"
      expect(clone).not_to eq(dto)

      dto.freeze
      expect(dto.clone.frozen?).to eq(true)
    }
  end
end