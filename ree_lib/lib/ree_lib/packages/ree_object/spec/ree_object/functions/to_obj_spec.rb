# frozen_string_literal: true

RSpec.describe :to_obj do
  link :to_obj, from: :ree_object

  let(:klass) {
    Class.new do
      attr_reader :integer, :settings

      def initialize
        @name = 'John'
        @work = 'Company'
        @array = [1, 'string', 3, { 'name' => 'Johny', 'last_name': 'Doe'}]
        @settings = Object.new
        @settings.instance_exec do
          @name = 'Steven'
          @last_name = 'Doe'
          @pass = 'pass'
        end
      end
    end
  }

  context "blank, string, array, boolean" do
    it {
      expect(to_obj(nil)).to eq(nil)
      expect(to_obj("")).to eq("")
      expect(to_obj("   ")).to eq("   ")
      expect(to_obj([])).to eq([])
      expect(to_obj(Hash.new)).to be_a(Object)
      expect(to_obj(Object.new).instance_variables).to eq([])
      expect(to_obj(false)).to eq(false)
      expect(to_obj(true)).to eq(true)
      expect(to_obj("test")).to eq("test")
      expect(to_obj([1, 2, 3])).to eq([1, 2, 3])
    }
  end

  context "Struct" do
    it {
      obj = to_obj(Struct.new(:id, :name).new(1, 'John'))

      expect(obj.name).to eq('John')
      expect(obj.id).to eq(1)
    }
  end

  context "OpenStruct" do
    it {
      require 'ostruct'
      obj = to_obj(OpenStruct.new(id: 1, name: 'John'))

      expect(obj.name).to eq('John')
      expect(obj.id).to eq(1)
    }
  end

  context "hash and object" do
    it {
      obj = to_obj(
        {
          name: 'John',
          settings: {
            pass: 'pass',
            last_name: 'Doe'
          }
        }
      )
      obj2 = to_obj(klass.new)

      expect(obj.name).to eq("John")
      expect(obj.settings.class).to be_a(Object)
      expect(obj2.name).to eq("John")
      expect(obj2.settings.class).to be_a(Object)
    }
  end

  context "custom object" do
    it {
      klass = Struct.new(:id, :object)
      object = Object.new

      object.instance_exec do
        @list = [1, 'string', klass.new(1, Object.new)]
      end

      obj = klass.new(1, object)

      result = to_obj(obj)

      expect(result.id).to eq(1)
      expect(result.object.list[0]).to eq(1)
      expect(result.object.list[1]).to eq('string')
      expect(result.object.list[2]).to be_a(Object)
    }
  end

  context "array" do
    it {
      obj = to_obj([1, 2, name: 'John'])
      obj2 = to_obj([1, 2, [3, name: 'John']])

      expect(obj[2]).to be_a(Object)
      expect(obj[2].name).to eq('John')
      expect(obj2[2][1]).to be_a(Object)
      expect(obj2[2][1].name).to eq('John')
    }
  end

  context "exclude option" do
    it {
      obj = to_obj(klass.new, exclude: [:name])

      expect(obj.respond_to?(:name)).to be false
      expect(obj.respond_to?(:work)).to be true
    }

    it {
      obj = to_obj(klass.new, exclude: [:name, {settings: [:pass]}])

      expect(obj.respond_to?(:name)).to be false
      expect(obj.respond_to?(:work)).to be true
      expect(obj.settings.respond_to?(:pass)).to be false
    }
  end

  context "global exclude option" do
    it {
      obj = to_obj(klass.new, global_exclude: [:name])

      expect(obj.respond_to?(:name)).to be false
      expect(obj.settings.pass).to eq('pass')
      expect(obj.settings.respond_to?(:name)).to be false
      expect(obj.array[3].last_name).to eq('Doe')
      expect(obj.array[3].respond_to?(:name)).to be false
    }
  end

  context "include option" do
    it {
      obj = to_obj(klass.new, include: [:name, :work])

      expect(obj.name).to eq('John')
      expect(obj.work).to eq('Company')
      expect(obj.respond_to?(:array)).to be false
      expect(obj.respond_to?(:settings)).to be false
    }
  end

  context "same include and exclude hash" do
    it {
      obj = to_obj(klass.new, include: [:settings], exclude:[{settings: [:pass]}])

      expect(obj.settings).to be_a(Object)
      expect(obj.settings.name).to eq('Steven')
      expect(obj.settings.respond_to?(:pass)).to be false
      expect(obj.respond_to?(:work)).to be false
    }
  end

  context "same include and exclude key" do
    it {
      expect {
        to_obj(klass.new, include: [:name], exclude:[:name])
      }.to raise_error(ArgumentError, /Exclude and include have the same values: /)
    }

    it {
      expect {
        to_obj(klass.new, include: [:name, :work], global_exclude:[:name])
      }.to raise_error(ArgumentError, /Exclude and include have the same values: /)
    }
  end
end