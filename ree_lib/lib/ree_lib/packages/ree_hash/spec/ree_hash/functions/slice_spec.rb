# frozen_string_literal: true

RSpec.describe :slice do
  link :slice, from: :ree_hash

  it {
    result = slice({:name => 'John', :last_name => "Doe", :age => 35, :pets => {:dog => "Dog" }}, :age, :pets)
    
    expect(result).to eq({:age => 35, :pets => {:dog => "Dog"}})
  }

  it {
    result = slice({name: 'John', last_name: "Doe"}, :test, raise: false)
    expect(result).to eq({})
  }

  it {
    expect {
      slice(
        {name: 'John', last_name: "Doe"},
        :test,
        raise: true
      )
    }.to raise_error(ReeHash::Slice::MissingKeyErr, "target hash does not have key `:test`") 
  }
end