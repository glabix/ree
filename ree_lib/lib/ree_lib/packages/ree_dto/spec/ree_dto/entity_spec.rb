# frozen_string_literal = true

package_require('ree_dto/entity')

RSpec.describe ReeEntity do
  before :all do
    class TestDTO < ReeEntity
      properties(
        id: Nilor[Integer],
        name: String,
        email: Nilor[String]
      )
    end

    @test_dto = TestDTO.new(
      id: 1,
      name: 'John',
      email: 'test@example.com'
    )

    @compare_dto = TestDTO.new(
      id: 1,
      name: 'John',
      email: 'test@example.com'
    )

    @uncompareable_dto = TestDTO.new(
      id: 3,
      name: 'Arthur'
    )
  end
  

  it { expect(@test_dto.id).to eq(1) }
  it { expect(@test_dto.name).to eq('John') }
  it { expect(@test_dto.email).to eq('test@example.com') }
  it { expect(@test_dto).to eq(@compare_dto) }
  it { expect(@test_dto).to_not eq(@uncompareable_dto)}

  context "missing args" do
    it {
      dto = TestDTO.new(name: 'John')
      expect(dto.id).to eq(nil)
      expect(dto.email).to eq(nil)
    }
  end

  context "#to_s" do
    it {
      expect(@test_dto.to_s).to eq(
%Q(
TestDTO
  email = test@example.com
  id    = 1
  name  = John)
      )
    }
  end

  context "#values_for" do
    it {
      dto = TestDTO.new(
        id:    1,
        name:  'John',
        email: 'test@example.com'
      )

      expect(dto.values_for(:id)).to eq([1])
      expect(dto.values_for(:id, :name)).to eq([1, 'John'])
      expect(dto.values_for(:email, :name)).to eq(['test@example.com', 'John'])
    }
  end

  context "#from" do
    it {
      StructDTO = Struct.new(:id, :name, :email, :phone)

      obj = StructDTO.new(1, 'John', 'test@example.com', '123123')

      dto = TestDTO.import_from(obj)

      expect(dto).to be_a(TestDTO)
      expect(dto.id).to eq(1)
      expect(dto.name).to eq('John')
      expect(dto.email).to eq('test@example.com')
    }
  end

  context "#to_h" do
    it {
      dto = TestDTO.new(
        id: 1,
        name: 'John',
        email: 'test@example.com',
      )

      expect(dto.to_h).to eq({
        id: 1,
        name: 'John',
        email: 'test@example.com'
      })
    }
  end
end