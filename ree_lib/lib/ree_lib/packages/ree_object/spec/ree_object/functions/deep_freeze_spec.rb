# frozen_string_literal: true

RSpec.describe :deep_freeze do
  link :deep_freeze, from: :ree_object

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

    let(:obj) { deep_freeze(klass.new) }

    it { expect(obj.frozen?).to eq(true) }
    it { expect(obj.integer.frozen?).to eq(true) }
    it { expect(obj.string.frozen?).to eq(true) }
    it { expect(obj.array.frozen?).to eq(true) }
    it { expect(obj.hash.frozen?).to eq(true) }
    it { expect(obj.hash.default.frozen?).to eq(true) }
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

      deep_freeze(hash)

      expect(hash[:name].frozen?).to eq(true)
      expect(hash[:array].frozen?).to eq(true)
      expect(hash[:array][0].frozen?).to eq(true)
      expect(hash[:array][0]['name'].frozen?).to eq(true)

    }
  end

  context "string" do
    it {
      str = "string"
      deep_freeze(str)

      expect(str.frozen?).to eq(true)
    }
  end

  context "symbol" do
    it {
      sym = :string
      deep_freeze(sym)

      expect(sym.frozen?).to eq(true)
    }
  end

  context "class" do
    it {
      obj = Object
      deep_freeze(obj)

      expect(obj.frozen?).to eq(false)
    }
  end

  context "module" do
    it {
      mod = ReeObject
      deep_freeze(mod)

      expect(mod.frozen?).to eq(false)
    }
  end

  context "recursive objects" do
    let(:obj_klass) {
      Class.new do
        def set(v)
          @value = v
        end

        def get_value()
          @value
        end
      end
    }

    it {
      obj = obj_klass.new
      obj.set([obj])

      deep_freeze(obj)
      expect(obj.frozen?).to eq(true)
      expect(obj.get_value.frozen?).to eq(true)
      expect(obj.get_value[0].frozen?).to eq(true)
    }
  end
end
