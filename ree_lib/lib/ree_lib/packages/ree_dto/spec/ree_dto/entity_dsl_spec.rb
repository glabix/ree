# frozen_string_literal = true

package_require('ree_dto/entity_dsl')

RSpec.describe ReeDto::EntityDSL do
  before :all do
    class TestTaskDTO
      include ReeDto::EntityDSL

      properties(
        id: Nilor[Integer],
        title: String
      )
    end

    class TestDTO
      include ReeDto::EntityDSL

      properties(
        id: Nilor[Integer],
        name: String,
        email: Nilor[String]
      )

      collection :tasks, Nilor[ArrayOf[TestTaskDTO]]
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
  it { expect(@test_dto == Object.new).to eq(false) }
  it { expect(@test_dto == @test_dto).to eq(true) }

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

  context "collection methods" do
    it {
      dto = TestDTO.new(
        id: 1,
        name: 'John',
        email: 'test@example.com',
      )

      expect(dto.respond_to? "set_tasks").to eq(true)
      expect(dto.respond_to? "tasks").to eq(true)

      task_1 = TestTaskDTO.new(id: 1, title: "new task")
      task_2 = TestTaskDTO.new(id: 2, title: "other task")

      dto.set_tasks([task_1, task_2])
      dto.tasks

      expect(dto.tasks.class).to eq(Array)
      expect(dto.tasks.size).to eq(2)
      expect(dto.tasks.first.class).to eq(task_1.class)
      expect(dto.tasks.last.class).to eq(task_2.class)
    }

    context "collection does not set" do
      it {
        dto = TestDTO.new(
          id: 1,
          name: 'John',
          email: 'test@example.com',
        )

        expect { dto.tasks }.to raise_error(ReeDto::EntityDSL::ClassMethods::PropertyNotSetError)
      }
    end

    context "collection set to nil" do
      it {
        dto = TestDTO.new(
          id: 1,
          name: 'John',
          email: 'test@example.com',
        )

        dto.set_tasks(nil)

        expect{ dto.tasks }.to_not raise_error
      }
    end

    context "collection contract errors" do
      it {
        dto = TestDTO.new(
          id: 1,
          name: 'John',
          email: 'test@example.com',
        )

        expect { dto.set_tasks([1,2,3]) }.to raise_error(Ree::Contracts::ContractError)
      }
    end
  end
end