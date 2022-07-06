# frozen_string_literal = true

RSpec.describe :deep_dup do
  link :deep_dup, from: :ree_object

  context "object" do
    let(:klass) {
      Class.new do
        attr_reader :integer, :string, :array, :hash, :object

        def initialize
          @integer = 1
          @string = 'string'
          @array = [1, 'string', 3, {name: 'John'}]
          @hash = {id: 1, 'test' => 2}
          @hash.default = "default"
          @object = Object.new
        end  
      end
    }

    let(:obj) { klass.new }
    let(:obj_dup) { deep_dup(obj) }

    it { expect(obj_dup).to be_a(klass) }
    it { expect(obj_dup.integer).to eq(1) }
    it { expect(obj_dup.integer.object_id).to eq(obj.integer.object_id) }
    it { expect(obj_dup.string).to eq('string') }
    it { expect(obj_dup.string.object_id).to_not eq(obj.string.object_id) }
    it { expect(obj_dup.array).to eq([1, 'string', 3, {name: 'John'}]) }
    it { expect(obj_dup.hash).to eq({id: 1, 'test' => 2}) }
    it { expect(obj_dup.hash.default).to eq("default") }
    it { expect(obj_dup.hash.default.object_id).to_not eq(obj.hash.default.object_id) }
    it { expect(obj_dup.object.class).to eq(Object) }
  end

  context "hash & array" do
    it {
      hash = {
        name: 'John',
        array: [
          {
            'name' => 'Doe'
          }
        ]
      }

      dup = deep_dup(hash)

      expect(dup[:name]).to eq('John')
      expect(dup[:name].object_id).to_not eq(hash[:name].object_id)
      expect(dup[:array]).to eq([{'name' => 'Doe'}])
      expect(dup[:array].object_id).to_not eq(hash[:array].object_id)
    }
  end

  context "string" do
    it {
      str = "string"
      dup = deep_dup(str)

      expect(dup).to eq(str)
      expect(dup.object_id).to_not eq(str.object_id)
    }
  end

  context "symbol" do
    it {
      sym = :string
      dup = deep_dup(sym)

      expect(dup).to eq(sym)
      expect(dup.object_id).to eq(sym.object_id)
    }
  end

  context "class" do
    it {
      obj = Object
      dup = deep_dup(obj)

      expect(dup).to eq(obj)
      expect(dup.object_id).to eq(obj.object_id)
    }
  end

  context "Struct" do
    it {
      obj = Struct.new(:id, :name).new(1, 'John')
      dup = deep_dup(obj)

      expect(dup).to eq(obj)
      expect(dup).to be_a(Struct)
      expect(dup.object_id).to_not eq(obj.object_id)
    }
  end

  context "OpenStruct" do
    it {
      require 'ostruct'
      obj = OpenStruct.new(id: 1, name: 'John')
      dup = deep_dup(obj)

      expect(dup).to eq(obj)
      expect(dup).to be_a(OpenStruct)
      expect(dup.object_id).to_not eq(obj.object_id)
    }
  end

  context "Object with singleton methods" do
    it {
      obj = Object.new

      def obj.hello
        'hello'
      end

      dup = deep_dup(obj)

      expect(dup.hello).to eq('hello')
    }
  end

  context "module" do
    it {
      obj = ReeObject
      dup = deep_dup(obj)

      expect(dup).to eq(obj)
      expect(dup.object_id).to eq(obj.object_id)
    }
  end

  context "recursive objects" do
    let(:obj_klass) {
      Class.new do
        def set(v)
          @value = v
        end
      end
    }

    it {
      obj = obj_klass.new
      obj.set([obj])

      deep_dup(obj)
    }
  end

  context "freeze" do
    it {
      obj = [
        {
          id: "id"
        }
      ]

      dup = deep_dup(obj, freeze: true)

      expect(dup.frozen?).to eq(true)
      expect(dup.first.frozen?).to eq(true)
      expect(dup.first[:id].frozen?).to eq(true)
    }
  end
end