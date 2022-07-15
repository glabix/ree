# frozen_string_literal = true

RSpec.describe :as_json do
  link :as_json, from: :ree_object

  context "object" do
    let(:klass) {
      Class.new do
        attr_reader :integer, :string, :array, :hash, :object

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
    }

    context "Struct" do
      it {
        klass = Struct.new(:id, :name)
        result = as_json(klass.new(1, 'John'))

        expect(result).to eq({id: 1, name: 'John'})
      }  
    end

    context "OpenStruct" do
      it {
        require 'ostruct'
        obj = OpenStruct.new(id: 1, name: 'John')
        result = as_json(obj)

        expect(result).to eq({id: 1, name: 'John'})
      }
    end

    context "basic types" do
      it {
        obj = Date.new
        result = as_json(obj)
        expect(result).to eq(obj)
      }

      it {
        obj = Time.new
        result = as_json(obj)
        expect(result).to eq(obj)
      }

      it {
        obj = 1
        result = as_json(obj)
        expect(result).to eq(obj)
      }

      it {
        obj = "string"
        result = as_json(obj)
        expect(result).to eq(obj)
      }

      it {
        obj = true
        result = as_json(obj)
        expect(result).to eq(obj)
      }

      it {
        obj = false
        result = as_json(obj)
        expect(result).to eq(obj)
      }

      it {
        obj = nil
        result = as_json(obj)
        expect(result).to eq(obj)
      }

      it {
        obj = :symbol
        result = as_json(obj)
        expect(result).to eq(obj)
      }

      it {
        obj = Object.new
        result = as_json(obj)
        expect(result).to eq({})
      }

      it {
        obj = Class
        result = as_json(obj)
        expect(result).to eq(obj)
      }

      it {
        obj = Module
        result = as_json(obj)
        expect(result).to eq(obj)
      }
    end

    context "object" do
      it {
        result = as_json(klass.new)
  
        expected = {
          integer: 1,
          string: 'string',
          array: [1, 'string', 3, { name: 'John'}],
          hash: {
            id: 1,
            test: 2,
            nested: {
              some_value: 1,
              another_value: 2
            },
            name: 'name'
          },
          klass: Object,
          module: Module,
          object: {
            name: 'John',
            last_name: 'Doe'
          }
        }
  
        expect(result).to eq(expected)
      }
    end

    context "check for recursion" do
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
  
        expect {
          as_json(obj)
        }.to raise_error(ReeObject::AsJson::RecursiveObjectErr, /Recursive object found: /)
      }
    end
  end
end