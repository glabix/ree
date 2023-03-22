# frozen_string_literal: true

RSpec.describe :dump_as_json do
  link :dump_as_json, from: :ree_object
  link :load_json_dump, from: :ree_object

  let(:klass) {
    class TestObjCLass
      attr_reader :integer, :string, :array, :hash, :object, :klass, :module

      def initialize
        @integer = 1
        @string = 'string'
        @array = [1, 'string', 3, { 'name' => 'John'}]

        @hash = {
          id: 1,
          'test' => 2,
          nested: {
            some_value: 1,
            another_value: 2
          },
          name: 'name'
        }

        @object = Object.new
        @klass = Object
        @module = Module

        @object.instance_exec do
          @name = 'John'
          @last_name = 'Doe'
        end
      end
    end

    TestObjCLass
  }

  context "object" do
    it {
      orig_obj = klass.new
      result = dump_as_json([orig_obj])
      obj = load_json_dump(result).first

      expect(obj.integer).to eq(orig_obj.integer)
      expect(obj.string).to eq(orig_obj.string)
      expect(obj.array).to eq(orig_obj.array)
      expect(obj.hash).to eq(orig_obj.hash)
      expect(obj.klass).to eq(orig_obj.klass)
      expect(obj.module).to eq(orig_obj.module)
      expect(obj.object.instance_variable_get(:@name)).to eq(orig_obj.object.instance_variable_get(:@name))
      expect(obj.object.instance_variable_get(:@last_name)).to eq(orig_obj.object.instance_variable_get(:@last_name))
    }
  end
end