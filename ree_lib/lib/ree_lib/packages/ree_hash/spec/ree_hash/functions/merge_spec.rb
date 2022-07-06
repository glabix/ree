# frozen_string_literal: true

RSpec.describe :merge do
  link :merge, from: :ree_hash

  context "deep" do
    it {
      first_hash = {:name => "John", :pets => { :dog => "Dog"}}
      other_hash = {:name => "Steven", :pets => { :cat => "Cat"}}
      merged_hash = {:name => "Steven", :pets => { :dog => "Dog", :cat => "Cat"}}
      result = merge(first_hash, other_hash)

      expect(result).to eq(merged_hash)
      expect(result.object_id).to_not eq(first_hash.object_id)
      expect(result.object_id).to_not eq(other_hash.object_id)
    }
  end

  context "deep = false" do
    it {
      first_hash = {:name => "John", :pets => { :dog => "Dog"}}
      other_hash = {:name => "Steven", :pets => { :cat => "Cat"}}
      merged_hash = {:name => "Steven", :pets => { :cat => "Cat"}}
      result =  merge(first_hash, other_hash, deep: false)

      expect(result).to eq(merged_hash)
      expect(result.object_id).to_not eq(first_hash.object_id)
      expect(result.object_id).to_not eq(other_hash.object_id)
    }
  end

  context "with block" do
    it {
      first_hash = {:name => "John", :pets => { :dog => "Dog"}}
      other_hash = {:name => "Steven", :pets => { :cat => "Cat"}}
      merged_hash = {:name => "John", :pets => { :dog => "Dog", :cat => "Cat"}}

      result =  merge(first_hash, other_hash) do |key, first_val, other_val|
        if first_val == "John"
          "John"
        end
      end

      expect(result).to eq(merged_hash)
    }
  end
end