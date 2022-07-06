# frozen_string_literal: true

RSpec.describe :transform_keys do
  link :transform_keys, from: :ree_hash

  context "deep" do
    it {
      hash = {id: 1, name: 'John', array: [1,2,3], hash: {id: 1, name: 'Doe'}}

      result = transform_keys(hash) { _1.to_s }

      expect(result).to eq(
        {'id' => 1, 'name' => 'John', 'array' => [1,2,3], 'hash' => {'id' => 1, 'name' => 'Doe'}}
      )
    }
  end

  context "deep = false" do
    it {
      hash = {id: 1, name: 'John', array: [1,2,3], hash: {id: 1, name: 'Doe'}}

      result = transform_keys(hash, deep: false) { _1.to_s }

      expect(result).to eq(
        {'id' => 1, 'name' => 'John', 'array' => [1,2,3], 'hash' => {id: 1, name: 'Doe'}}
      )
    }
  end

  context "default" do
    it {
      hash = {id: 1, name: 'John', array: [1,2,3], hash: {id: 1, name: 'Doe'}}
      hash.default = 1

      result = transform_keys(hash, deep: false) { _1.to_s }

      expect(result.default).to eq(1)
      expect(result['hash'].default).to eq(nil)
    }

    it {
      hash = {id: 1, name: 'John', array: [1,2,3], hash: {id: 1, name: 'Doe'}}
      hash.default_proc = Proc.new { 1 }

      result = transform_keys(hash, deep: false) { _1.to_s }

      expect(result.default_proc).to eq(hash.default_proc)
      expect(result['hash'].default).to eq(nil)
    }

    it {
      obj = {id: 1, name: 'Doe'}
      obj.default = 2

      hash = {id: 1, name: 'John', array: [1,2,3], hash: obj}
      hash.default = 1

      result = transform_keys(hash, deep: false) { _1.to_s }

      expect(result.default).to eq(1)
      expect(result['hash'].default).to eq(2)
    }

    it {
      obj = {id: 1, name: 'Doe'}
      obj.default_proc = Proc.new { 2 }

      hash = {id: 1, name: 'John', array: [1,2,3], hash: obj}
      hash.default = 1

      result = transform_keys(hash, deep: false) { _1.to_s }

      expect(result.default).to eq(1)
      expect(result['hash'].default_proc).to eq(obj.default_proc)
    }
  end
end